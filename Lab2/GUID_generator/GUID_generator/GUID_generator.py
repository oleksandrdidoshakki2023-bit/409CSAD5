import uuid


def generate_guid(pib_text=''):
  if pib_text.strip():
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, pib_text.strip()))
  return str(uuid.uuid4())


def parse_pcb_specs(guid_str):
  groups = guid_str.split('-')
  print('\n' + '=' * 45)
  print(f'Generated GUID: {guid_str}')
  print('=' * 45)
  print('PCB Specs:')
  print('-' * 45)

  for i, group in enumerate(groups, start=1):
    side_size = len(group)
    print(
        f'U{i}: Group "{group}" | Pins: {side_size} | Size: {side_size}x{side_size}'
        ' mm'
    )

  print('-' * 45)


if __name__ == '__main__':
  user_input = input('Enter Student Name (or press Enter): ')
  current_guid = generate_guid(user_input)
  parse_pcb_specs(current_guid)