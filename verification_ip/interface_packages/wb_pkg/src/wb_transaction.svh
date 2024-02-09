class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)


   typedef bit [7:0] mybit;
   typedef mybit trans_arr[];

   typedef wb_transaction this_type;
   static this_type type_handle = get_type();

   static function this_type get_type();
      if(type_handle == null)
        type_handle = new();
      return type_handle;
   endfunction

   virtual function wb_transaction get_type_handle();
     return get_type();
   endfunction

   bit [wb_addr_wid-1:0] wb_addr;
   bit [wb_data_wid-1:0] wb_data, cmd_data;
   wb_op_t wb_op;
   static bit irq = 0;

   virtual function string convert2string();
      //return {super.convert2string(), $sformatf("Wishbone Addr : %h Data: %h WE : %h",wb_addr,wb_data, wb_op)};
  endfunction

  function new(string name="");
      super.new(name);
  endfunction

  virtual function bit [7:0] get_addr();
    return this.wb_addr;
  endfunction

  virtual function this_type set_addr(bit [wb_addr_wid-1:0] addr);
    this.wb_addr = addr;
    return this;
  endfunction

  virtual function this_type set_op(wb_op_t OP);
    this.wb_op = OP;
    return this;
  endfunction

  virtual function bit get_op();
    return this.wb_op;
  endfunction

  virtual function this_type set_data(bit [wb_data_wid-1:0] data);
    this.wb_data = data;
    return this;
  endfunction

  virtual function bit [wb_data_wid-1:0] get_data_0();
    return this.wb_data;
  endfunction

virtual function automatic trans_arr get_data();
      trans_arr return_dyn_arr;
      return_dyn_arr = new[0];
      return_dyn_arr[0] = this.wb_data;
      return return_dyn_arr;
endfunction


  virtual function bit compare(wb_transaction rhs);
    return ((this.get_addr() == rhs.get_addr()) && (this.get_data() == rhs.get_data()) &&(this.get_op() == rhs.get_op()));
  endfunction
   
endclass //className