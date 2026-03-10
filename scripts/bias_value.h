#ifndef BIAS_VALUE_H
#define BIAS_VALUE_H

#include <stdint.h>

static const int32_t conv_bias[8] = {
  -374,
  169,
  -48,
  208,
  82,
  6,
  -1201,
  -694
};

static const int32_t fc_bias[4] = {
  427,
  -518,
  -94,
  186
};

#endif