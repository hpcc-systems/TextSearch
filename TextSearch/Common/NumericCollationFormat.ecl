/*
  <Numeric collation format>

  Layout in big endian:
    |s|eeeeeee|ffffffffffffffffff|
      s - sign bit; positive(1), negative(0)
      e - 7 bit biased exponent; from -63 to 64
          s = 0: 64 - (exponent value)
          s = 1: (exponent value) + 63
      f - 24 bit biased fraction; 6 digit packed binary coded decimal
          s = 0: 0x999999 - (fraction value in packed BCD)
          s = 1: (fraction value in packed BCD)
*/
EXPORT NumericCollationFormat := MODULE
  EXPORT UNSIGNED4 StringToNCF(STRING numstr) := BEGINC++
    #option pure
    const unsigned digitBytes = sizeof(unsigned) - sizeof(char);
    const int bufSz = digitBytes << 1;  // number of digits in packed BCD
    const unsigned digitBits = digitBytes << 3;
    const unsigned ZERO = 0x80000000;
    const unsigned N_ZERO = 0x7F999999;
    const int SIGN = 0x80;
    const int EXPMAX = 64;
    const int EXPMIN = -63;

    bool neg = *numstr == '-';
    unsigned rslt = 0;

    if (neg)
    {
      numstr++;
      lenNumstr--;
    }

    int nzFirst = lenNumstr;
    bool nzFound = false;
    int dpAt = -1;
    int storedDigits = 0;
    int expnt = 0;
    char ch = '\0';

    for (int i = 0; i < lenNumstr; i++)
    {
      if ((ch = numstr[i]) == '.')
      {
        dpAt = i;
        continue;
      }
      else if (ch < 0x30 || ch > 0x39)
      {
        dpAt = dpAt >= 0 ? dpAt : i;
        break;
      }
      else if (ch != '0')
      {
        nzFirst = i < nzFirst ? i : nzFirst;
        nzFound = true;
      }
      if (nzFound && storedDigits < bufSz)
      {
        rslt = rslt << 4 | (neg ? 0x39 - ch : ch - 0x30);
        storedDigits++;
      }
    }

    if (!nzFound)
      rslt = ZERO;
    else
    {
      expnt = dpAt >= 0 ? (dpAt > nzFirst? dpAt - nzFirst : dpAt - nzFirst + 1) : lenNumstr - nzFirst;

      if (expnt > EXPMAX)
        // modulus too large; assign the return value to the smallest or the largest
        rslt = neg ? 0x00000000 : 0xFF999999;
      else if (expnt < EXPMIN)
        // too minute; so it is zero
        rslt = neg ? N_ZERO : ZERO;
      else
      {
        unsigned upperByte = neg ? EXPMAX - expnt : expnt - EXPMIN + SIGN;

        while (storedDigits++ < bufSz)
          rslt = rslt << 4 | (neg ? 9 : 0);
        rslt |= upperByte << digitBits;
      }
    }
    return rslt;
  ENDC++;

  EXPORT REAL NCFtoREAL(UNSIGNED4 ncf) := BEGINC++
    #include <math.h>
    #option pure
    const unsigned digitBytes = sizeof(unsigned) - sizeof(char);
    const int bufSz = digitBytes << 1;
    const unsigned digitBits = digitBytes << 3;
    const unsigned SGN_MASK = 0x80000000;
    const unsigned EXP_MASK = 0x7F;
    const unsigned DIGIT_MASK = 0x0F;

    bool pos = (ncf & SGN_MASK) != 0;
    int expv = ncf >> digitBits & EXP_MASK;
    double rslt = 0;
    unsigned sbits = digitBits;
    unsigned char d = 0;
    int frc = 0;

    for (int i = 0; i++ < bufSz;)
    {
      sbits -= 4;
      d = ncf >> sbits & DIGIT_MASK;
      frc = 10 * frc + (pos ? d : 9 - d);
    }
    rslt = pos ? frc : -frc;
    rslt *= pow(10, (pos ? expv - 63 : 64 - expv) - bufSz);
    return rslt;
  ENDC++;
END;
