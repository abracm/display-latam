struct Status {
	char           state;
	unsigned short minutes;
	unsigned short decaseconds;
	unsigned short seconds;
	unsigned short deciseconds;
	unsigned short centiseconds;
	unsigned short miliseconds;
};

int
decode_status(char bytes[10], struct Status *s);

