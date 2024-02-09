class wb_irq_transaction extends wb_transaction;
  `ncsu_register_object(wb_irq_transaction)

  typedef bit [7:0] mybit;
  typedef mybit trans_arr[];
  
  typedef wb_irq_transaction this_type;
  static this_type type_handle = get_type();

  static function this_type get_type();
      if(type_handle == null)
        type_handle = new();
      return type_handle;
  endfunction

  virtual function wb_irq_transaction get_type_handle();
     return get_type();
  endfunction

// in order to differentiate from original wb_transaction
// in fact, there is no need to read out this bit
// detect instance type can reach the same purpose
static bit irq = 1; 

function new(string name="");
    super.new(name);
endfunction

virtual function string convert2string();
    return {super.convert2string(),$sformatf("irq bit : %b", irq )};
endfunction
/*
  function bit compare(wb_irq_transaction rhs);
    return ((this.addr  == rhs.addr ) &&
            (this.data == rhs.data) &&
            (this.we == rhs.we));
  endfunction
*/

virtual function bit [8-1:0] get_addr();
      return 0;
endfunction

virtual function bit get_op();
      return 0;
endfunction

virtual function bit [7:0] get_data_0();
      return irq;
endfunction

virtual function bit compare (wb_transaction rhs);
    return 1'b0;
endfunction

virtual function automatic trans_arr get_data();
      trans_arr return_dyn_arr;
      return_dyn_arr = new[0];
      return_dyn_arr[0] = this.irq;
      return return_dyn_arr;
endfunction


endclass
