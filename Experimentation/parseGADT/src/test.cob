
recipe apa {
  conv [strides := [2, 2, 2]]
  relu []
  batch_normalize []
}

recipe bepa {
  conv [strides := [3,3]]
  relu []
  apa
}

model my_model {
  apa
  apa
  bepa
  bepa  
}
