class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)

   typedef i2c_transaction this_type;
   static this_type type_handle = get_type();

   typedef bit [7:0] mybit;
   typedef mybit trans_arr[];

   static function this_type get_type();
      if(type_handle == null)
        type_handle = new();
      return type_handle;
   endfunction

   virtual function i2c_transaction get_type_handle();
     return get_type();
   endfunction

   bit [i2c_data_wid-1:0] i2c_data [];
   bit [i2c_addr_wid-1:0] i2c_addr;
   i2c_op_t i2c_op;
   bit ack;

  function new(string name=""); 
    super.new(name);
  endfunction : new

  virtual function string convert2string();
      if(this.i2c_op == I2C_WRITE) // I2C write
        return {super.convert2string(), $sformatf("write data: %p",i2c_data)};
      else 
        return {super.convert2string(), $sformatf("read data: %p",i2c_data)};
  endfunction

  function this_type set_op(i2c_op_t op);
    this.i2c_op = op;
    return this;
  endfunction
  
  virtual function bit [7:0] get_addr();
    return {this.ack,this.i2c_addr};
  endfunction

  virtual function bit get_op();
    return this.i2c_op;
  endfunction

  virtual function this_type set_data(bit [i2c_data_wid-1:0] data_buf[$]);
    this.i2c_data = new[data_buf.size()];
    this.i2c_data = {>>{data_buf}};
    return this;
  endfunction

  virtual function bit [7:0] get_data_0();
    return this.i2c_op;
  endfunction

  virtual function trans_arr get_data();
    trans_arr return_dyn_arr;
    return_dyn_arr = i2c_data;
    return return_dyn_arr;
  endfunction

  virtual function bit compare(i2c_transaction rhs);
    return (this.get_addr() == rhs.get_addr()) && (this.get_data() == rhs.get_data());
  endfunction

endclass
