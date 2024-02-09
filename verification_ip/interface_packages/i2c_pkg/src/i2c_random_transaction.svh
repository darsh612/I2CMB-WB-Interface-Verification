class i2c_random_transaction extends i2c_transaction;
	`ncsu_register_object(i2c_random_transaction)

    typedef i2c_random_transaction this_type;
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

	rand bit[i2c_data_wid-1:0] i2c_rand_data[];

	constraint transfer_size { 0 < i2c_rand_data.size() && i2c_rand_data.size() <= 10; }

	function new(string name = "");
		super.new(name);
	endfunction : new

	virtual function string convert2string();
		return {super.convert2string(), $sformatf("read random data: %p", i2c_rand_data)};
	endfunction

	function this_type set_op(i2c_op_t op);
		void'(super.set_op(op));
		return this;
	endfunction

	virtual function bit [8-1:0] get_data_0();
	      return this.i2c_rand_data[0];
	endfunction

	virtual function trans_arr get_data();
		trans_arr return_dyn_arr;
          return_dyn_arr = i2c_rand_data;
          return return_dyn_arr;
    endfunction
 
  


endclass