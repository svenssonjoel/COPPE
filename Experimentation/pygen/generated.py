import checkpoint as checkpoint
import tensorflow.compat.v1 as tf
import json as json
import numpy as np
import os as os


with open("checkpoint/code_gen_test.json") as f:
    network = json.load(f)


def model(input_data, network):
    conv_filters = tf.keras.initializers.glorot_uniform(seed=None)(shape=(3, 3, input_data.get_shape().as_list()[3], 16))
    conv_filters = checkpoint.setup_variable(network['layers'][1]['value'], init=tf.Variable, init_value=conv_filters, var_name='conv/filters')

    conv = tf.nn.conv2d(input=input_data, filters=conv_filters, padding='SAME', strides=[1, 1], name='conv')
    network['layers'][1]['value']['var']['conv/filters'] = conv_filters
    network['layers'][1]['value']['tensor'] = conv
    another_conv_0_filters = tf.keras.initializers.glorot_uniform(seed=None)(shape=(3, 3, conv.get_shape().as_list()[3], 16))
    another_conv_0_filters = checkpoint.setup_variable(network['layers'][2]['value'], init=tf.Variable, init_value=another_conv_0_filters, var_name='another_conv_0/filters')

    another_conv_0 = tf.nn.conv2d(input=conv, filters=another_conv_0_filters, padding='SAME', strides=[1, 1], name='another_conv_0')
    network['layers'][2]['value']['var']['another_conv_0/filters'] = another_conv_0_filters
    network['layers'][2]['value']['tensor'] = another_conv_0
    another_conv_1_filters = tf.keras.initializers.glorot_uniform(seed=None)(shape=(3, 3, another_conv_0.get_shape().as_list()[3], 16))
    another_conv_1_filters = checkpoint.setup_variable(network['layers'][3]['value'], init=tf.Variable, init_value=another_conv_1_filters, var_name='another_conv_1/filters')

    another_conv_1 = tf.nn.conv2d(input=another_conv_0, filters=another_conv_1_filters, padding='SAME', strides=[1, 1], name='another_conv_1')
    network['layers'][3]['value']['var']['another_conv_1/filters'] = another_conv_1_filters
    network['layers'][3]['value']['tensor'] = another_conv_1
    another_conv_2_filters = tf.keras.initializers.glorot_uniform(seed=None)(shape=(3, 3, another_conv_1.get_shape().as_list()[3], 16))
    another_conv_2_filters = checkpoint.setup_variable(network['layers'][4]['value'], init=tf.Variable, init_value=another_conv_2_filters, var_name='another_conv_2/filters')

    another_conv_2 = tf.nn.conv2d(input=another_conv_1, filters=another_conv_2_filters, padding='SAME', strides=[1, 1], name='another_conv_2')
    network['layers'][4]['value']['var']['another_conv_2/filters'] = another_conv_2_filters
    network['layers'][4]['value']['tensor'] = another_conv_2
    another_conv_filters = tf.keras.initializers.glorot_uniform(seed=None)(shape=(3, 3, another_conv_2.get_shape().as_list()[3], 16))
    another_conv_filters = checkpoint.setup_variable(network['layers'][5]['value'], init=tf.Variable, init_value=another_conv_filters, var_name='another_conv/filters')

    another_conv = tf.nn.conv2d(input=another_conv_2, filters=another_conv_filters, padding='SAME', strides=[1, 1], name='another_conv')
    network['layers'][5]['value']['var']['another_conv/filters'] = another_conv_filters
    network['layers'][5]['value']['tensor'] = another_conv
    dense_10kc_weights = tf.keras.initializers.glorot_uniform(seed=None)(shape=(np.prod(another_conv.get_shape().as_list()[1:]), 10))
    dense_10kc_weights = checkpoint.setup_variable(network['layers'][6]['value'], init=tf.Variable, init_value=dense_10kc_weights, var_name='dense_10kc/weights')
    dense_10kc_bias = tf.zeros(shape=(10,))
    dense_10kc_bias = checkpoint.setup_variable(network['layers'][6]['value'], init=tf.Variable, init_value=dense_10kc_bias, var_name='dense_10kc/bias')
    another_conv = tf.reshape(another_conv, [-1, np.prod(another_conv.get_shape().as_list()[1:])])
    dense_10kc = tf.nn.xw_plus_b(x=another_conv, biases=dense_10kc_bias, weights=dense_10kc_weights, name='dense_10kc')
    network['layers'][6]['value']['var']['dense_10kc/bias'] = dense_10kc_bias
    network['layers'][6]['value']['var']['dense_10kc/weights'] = dense_10kc_weights
    network['layers'][6]['value']['tensor'] = dense_10kc


    d_1 = tf.nn.dropout(x=dense_10kc, rate=0.4, name='d_1')
    network['layers'][7]['value']['tensor'] = d_1
    regularizer = 0.002000 * (tf.nn.l2_loss(t=conv_filters, name='regularizer/conv') + tf.nn.l2_loss(t=another_conv_0_filters, name='regularizer/another_conv_0') + tf.nn.l2_loss(t=another_conv_1_filters, name='regularizer/another_conv_1') + tf.nn.l2_loss(t=another_conv_2_filters, name='regularizer/another_conv_2') + tf.nn.l2_loss(t=another_conv_filters, name='regularizer/another_conv'))
    return regularizer


data = np.random.rand(32, 32, 3)
input_tensor = tf.placeholder(dtype=tf.float32, shape=(None, 32, 32, 3), name='input_data')
output = model(input_tensor, network)
