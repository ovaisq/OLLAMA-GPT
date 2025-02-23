# utils.py
# ©2024, Ovais Quraishi

import datetime
import json
import locale
import logging
import time
import random
import requests
import string
from datetime import datetime as DT
from database import get_icd_billable_estimates

# set the locale English (United States)
locale.setlocale(locale.LC_ALL, 'en_US')

# substrings to be replaced
TBR = ["As an AI language model, I don't have personal preferences or feelings. However,",
       "As an AI language model, I don't have personal preferences or opinions, but ",
       "I'm sorry to hear you're feeling that way! As an AI language model, I don't have access to real-time information on Hypmic or its future plans. However,",
       "As an AI language model, I don't have personal beliefs or experiences. However,",
       "I'm just an AI, I don't have personal beliefs or opinions, and I cannot advocate for or against any particular religion. However,",
       "As an AI, I don't have real-time information on specific individuals or their projects. However,"
      ]

def sanitize_string(a_string):
    """Search and replace AI model related text in strings"""

    for i in TBR:
        if i in a_string:
            a_string = a_string.replace(i,'FWIW - ')
    return a_string

def unix_ts_str():
    """Unix time as a string"""

    dt = str(int(time.time())) # unix time
    return dt

def unix_ts_int():
    """Unix time as a string"""

    dt = int(time.time()) # unix time
    return dt

def ts_int_to_dt_obj():
    """Convert Unix time to date time object for timestamp column in PostgreSQL table"""
    epoch_timestamp = unix_ts_int()
    datetime_object = DT.fromtimestamp(epoch_timestamp, tz=datetime.timezone.utc)
    return datetime_object

def gen_internal_id():
    """Generate 10 number internal document id"""

    ten_alpha_nums = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))
    return ten_alpha_nums

def list_into_chunks(a_list, num_elements_chunk):
    """Split list into list of lists with each list containing
        num_elements_chunk elements
    """

    if len(a_list) > num_elements_chunk:
        for i in range(0, len(a_list), num_elements_chunk):
            yield a_list[i:i + num_elements_chunk]
    else:
        yield a_list

def sleep_to_avoid_429(counter):
    """Sleep for a random number of seconds to avoid 429
        TODO: handle status code from the API
        but it's better not to trigger the 429 at all...
    """

    counter += 1
    if counter > 23: # anecdotal magic number
        sleep_for = random.randrange(65, 345)
        logging.info(f"Sleeping for {sleep_for} seconds")
        time.sleep(sleep_for)
        counter = 0
    return counter

def serialize_datetime(obj): 
    """Credit: https://www.geeksforgeeks.org/how-to-fix-datetime-datetime-not-json-serializable-in-python/
    """

    if isinstance(obj, (datetime.datetime, datetime.datetime)): 
        return obj.isoformat() 
    raise TypeError("Type not serializable")

def check_endpoint_health(url):
    """Check if endpoint is available
    """

    try:
        response = requests.head(url)
        if response.status_code == requests.codes.ok:
            return True
        else:
            return False
    except requests.exceptions.RequestException:
        return False

def retry_with_timeout(max_retry_count, timeout_seconds, func, *args, **kwargs):
    """Retry logic
    """

    start_time = time.time()
    retry_count = 0
    while True:
        try:
            return func(*args, **kwargs)
        except Exception as e:
            retry_count += 1
            if retry_count >= max_retry_count or time.time() - start_time >= timeout_seconds:
                raise e
            print(f"Retry {retry_count} failed. Retrying...")
            time.sleep(1)  # Wait for 1 second before retrying

def replace_newline_in_dict(a_dict, replacement=''):
    """Remove newlines from a dict object generated by LLM
    """

    if isinstance(a_dict, dict):
        for key, value in a_dict.items():
            a_dict[key] = replace_newline_in_dict(value, replacement)
            a_dict[key] = replace_newline_in_dict(value, '  ')
    elif isinstance(a_dict, list):
        for i, item in enumerate(a_dict):
            a_dict[i] = replace_newline_in_dict(item, replacement)
            a_dict[i] = replace_newline_in_dict(item, '  ')
    elif isinstance(a_dict, str):
        a_dict = a_dict.replace('\n', replacement)
        a_dict = a_dict.replace('  ', replacement)
    return a_dict

def parse_fees_from_text(input_text):
    """Parse fees and frequency rates from a list of text descriptions.
    """

    costs = []
    frequency_parts = []

    words = input_text.split()

    for word in words:
        if word.startswith('$'):
            if '-' in word and len(word) > 1:
                min_cost, max_cost = word.split('-')
                costs.append(min_cost)
                costs.append(max_cost)
            else:
                costs.append(word)
        elif word == '-':
            frequency_parts.append(' ')
        else:
            frequency_parts.append(word)

    # both min and max values must be present
    if len(costs) == 1:
        costs.append(costs[0])

    # parsed object
    parsed_obj = {
                    'original_text': input_text,
                    'min_val': costs[0] if costs else '',
                    'max_val': costs[1] if len(costs) > 1 else '',
                    'frequency_rate': ' '.join(frequency_parts).replace('  ', ' ').strip() if frequency_parts else ''
                    }

    return json.loads(json.dumps(parsed_obj))

def calculate_medical_costs(patient_id):
    """Calculate and display fees for medical services related to a patient
       with a given patient_id. It does this by retrieving estimates from an
       ICD (International Classification of Diseases) source, parsing these
       estimates into fees.
    """

    def parse_and_calculate_estimates(cost):
        """Parse fees from text and calculate the average estimates for medical
            and insurance, if available.
        """

        medical = parse_fees_from_text(cost['medical_provider_reimbursement_rate'])
        insurance = parse_fees_from_text(cost['insurance_company_reimbursement_rate'])

        def get_average_estimate(fees):
            """Calculate the average estimate from min and max values, if they
                exist.
            """

            if fees['min_val'] and fees['max_val']:
                min_val = locale.atof(fees['min_val'].strip('$'))
                max_val = locale.atof(fees['max_val'].strip('$'))
                return (min_val + max_val) / 2
            return None

        medical_estimate = get_average_estimate(medical)
        insurance_estimate = get_average_estimate(insurance)

        return medical_estimate, insurance_estimate

    costs = get_icd_billable_estimates(patient_id)

    for cost in costs:
        medical_estimate, insurance_estimate = parse_and_calculate_estimates(cost)

        # TODO: build object so that it can be stored anywhere
        #if medical_estimate is not None:
        #    print(cost['code'])
        #    print('medical_estimate', '${:,.2f}'.format(medical_estimate))
        #    print('insurance_estimate', '${:,.2f}'.format(insurance_estimate))



#DEBUG 
#print ('Billing Estimate for patient am1jc0r0mo')
#calculate_medical_costs('am1jc0r0mo')

#print ('Billing Estimate for patient jy5aaylsvm')
#calculate_medical_costs('jy5aaylsvm')
