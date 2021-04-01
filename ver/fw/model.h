#ifndef __FWMODEL_H
#define __FWMODEL_H

#include "dsp16_model.h"

#include <cstdlib>
#include <exception>
#include <iostream>
#include <iomanip>

class Model {
    DSP16 st;
    DSP16_in inputs;
    i16 *rom, *ram;
public:
    Model( ROM& rom_data ) {
        rom = rom_data.data();
        ram = new i16[0x1000];
        std::memset( &inputs, 0, sizeof(DSP16_in));
        std::memset( &st, 0, sizeof(DSP16) );
        inputs.clk_en=1;
        st.div = 1;
    }
    ~Model() { delete []ram; ram=nullptr; }
    void set_irq( int irq ) { inputs.irq = irq; }
    void pbus_in( int v ) { inputs.pbus_in = v; }
    void rb_din( int v ) { inputs.rb_din=v; }
    void clk(int p) {
        inputs.clk=0;
        p<<=1;
        while( p-->0 ) {
            inputs.clk = 1-inputs.clk;
            eval_DSP16( &st, &inputs, rom, ram );
        }
    }
    // register access
    int pc() { return st.pc; }
    int r0() { return st.yauu_regs[R0]; }
    int r1() { return st.yauu_regs[R1]; }
    int r2() { return st.yauu_regs[R2]; }
    int r3() { return st.yauu_regs[R3]; }
    int  j() { return st.yauu_regs[ J]; }
    int  x() { return st.x; }
    int yh() { return st.y>>16; }
    int yl() { return st.y&0xFFFF; }
    int  p() { return st.p; }
    i64 a0() { return st.a[0]; }
    i64 a1() { return st.a[1]; }
    int fault() { return st.fault; }
    // status access
    bool in_cache() { return st.cache.k>0; }
};

#define CHECK( a ) if( ref.a() != dut.a() ) good=false;
#define PRINTM( a, M ) std::cout << std::setfill(' ') << std::setw(2) << #a << " = " \
                                 << std::setfill('0') << std::setw(4) \
                                 << std::hex << (ref.a()&M) << " - " \
                                 << std::setfill('0') << std::setw(4) \
                                 << std::hex << (dut.a()&M) \
                                 << (ref.a()!=dut.a()?'*':' ') \
                                 <<'\n';

class Dual {
    Model &ref;
    RTL   &dut;
    i64 ticks;

    void side_dump() {
        std::cout << "      Ref - DUT         (" << std::dec << ticks << ")\n";
        PRINTM( pc, 0xFFFF )
        PRINTM( r0, 0xFFFF )
        PRINTM( r1, 0xFFFF )
        PRINTM( r2, 0xFFFF )
        PRINTM( r3, 0xFFFF )
        PRINTM(  j, 0xFFFF )
        PRINTM(  x, 0xFFFF )
        PRINTM( yh, 0xFFFF )
        PRINTM( yl, 0xFFFF )
        PRINTM(  p, 0xFFFFFFFF )
        PRINTM( a0, ~0L )
        PRINTM( a1, ~0L )
    }

    void cmp() {
        bool good = true;
        static int bad=0;
        if( /*!ref.in_cache()*/ 1) {
            //CHECK( pc );
            CHECK( r0 );
            CHECK( r1 );
            CHECK( r2 );
            CHECK( r3 );
            CHECK(  j );
            CHECK(  x );
            CHECK( yh );
            CHECK( yl );
            CHECK(  p );
            CHECK( a0 );
            CHECK( a1 );
        }
            side_dump();
        if( !good ) {
            if( ++bad > 4 )
                throw std::runtime_error("Error: Ref and DUT diverged\n");
        }
        if( ref.fault() )
            throw std::runtime_error("Error: Ref is in fault state\n");
    }

    bool do_comp=true;
public:
    Dual( Model& _ref, RTL& _dut ) : ref(_ref), dut(_dut), ticks(0) { }
    void set_irq(int irq) {
        dut.set_irq(irq);
        ref.set_irq(irq);
    }
    void pbus_in(int v) {
        dut.pbus_in(v);
        ref.pbus_in(v);
    }
    void clk(int p) {
        // each one could go in a different thread
        while ( p-->0 ) {
            dut.clk(1);
            ref.clk(1);
            ticks++;
            if(do_comp) cmp();
        }
    }
    void rb_din( int v ) {
        dut.rb_din(v);
        ref.rb_din(v);
    }
    void nocomp() { do_comp=false; }
};

#undef CHECK
#undef PRINTM

#endif