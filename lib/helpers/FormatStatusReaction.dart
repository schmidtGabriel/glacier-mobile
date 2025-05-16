String FormatStatusReaction(String status) {
  switch (status) {
    case '0':
      return 'Pending';
    case '1':
      return 'Sent';
    case '10':
      return 'Approved';
    case '-10':
      return 'Rejected';
    default:
      return 'Unknown status';
  }
}
