CREATE OR REPLACE PACKAGE num
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

 Contains utility routines to deal with numeric types, values and result sets.

<pre>
Artisan      Date      Comments
============ ========= ========================================================
bcoulam      1997Dec30 Creation

<i>
    __________________________  LGPL License  ____________________________
    Copyright (C) 1997-2008 Bill Coulam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
    
*******************************************************************************/
AS

--------------------------------------------------------------------------------
--                               PUBLIC CURSORS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                PUBLIC TYPES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                 PUBLIC CONSTANTS, VARIABLES, EXCEPTIONS, ETC.
--------------------------------------------------------------------------------

INTEGER_MASK CONSTANT VARCHAR2(40) := 'FM999G999G999G999';
FLOAT_MASK CONSTANT VARCHAR2(40) := 'FM999G999G999G990D0009';

--------------------------------------------------------------------------------
--                              PUBLIC FUNCTIONS
--------------------------------------------------------------------------------

/**-----------------------------------------------------------------------------
get_set_diff:
 Compares two nested tables of number, returning a list of any number in set one
 that doesn't appear in set two. The datatype of the parameters is that of the
 independent num_tt type created during framework installation.
 
%note
 The need for this function is moot starting with 10g, due to the new SUBMULTISET
 comparison operator for collections.

%param i_ntab1 First collection of items to compare
%param i_ntab2 Second collection of items to compare
------------------------------------------------------------------------------*/
FUNCTION get_set_diff
(
   i_ntab1 IN num_tt
,  i_ntab2 IN num_tt
) RETURN num_tt;

/**-----------------------------------------------------------------------------
parse_list:
This function takes a delimited list of values and returns a collection of numbers, 
that can subsequently be used to join in SQL queries or used in other processing.

If your delimiter is something other than a comma, change the value of the second
parameter, i_delimiter, to the delimiter you want. It can handle multiple-character
delimiters if you need that, e.g. :: or => and other such dividers and seperators.

%param i_string The actual delimited list that will be broke out into individual
                numbers in a nested table collection.
                
%param i_delimiter Default is ",". The delimiter used to split up the numeric tokens.

%param i_ignore_nulls If you specify or allow the default of Y, then any 
                      consecutive delimiters in the list will be eliminated.
                      For example, 1,2,,4,5 will only return 4 integer values.
                      If you specify N, then consecutive delimiters will be
                      treated as a NULL value that is desired.
                      For example, 1,2,,4,5 will return 5 elements in the 
                      nested_table. The third value will be a NULL.

%return Nested table of numbers.
------------------------------------------------------------------------------*/
FUNCTION parse_list
(
   i_string       IN VARCHAR2,
   i_delimiter    IN VARCHAR2 DEFAULT ',',
   i_ignore_nulls IN VARCHAR2 DEFAULT 'Y'
) RETURN num_tt;

/**-----------------------------------------------------------------------------
make_list:
 Takes an array of numbers and returns a delimited list of the same in a single
 string. The returned string can be up to 32757 bytes long, so the receiving
 variable or column should be the same size, or the result should be truncated
 using SUBSTR.

%param i_coll The collection to be joined into a single string, separated by
              the given delimiter. 
              
%param i_delimiter List delimiter, defaults if not given
------------------------------------------------------------------------------*/
FUNCTION make_list
(
   i_coll IN num_tt
  ,i_delimiter IN VARCHAR2 DEFAULT ','
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
IaNb/IaN:
 Determines if a given string is a number.
 As in other libraries this function stands for Is a Number. Therefore, if it
 returns true, the value is a number. If it returns false, then it is a string or
 alphanumeric mix.

 You may pass a number to this function as well, but you probably already know
 it's a number, so that's not useful. If you pass a number, it will be implicitly
 converted to a string to perform the operation.

%design
 The suffix at the end of each version indicates the type returned by the function.
 The version which returns a number (using cnst.TRUE and cnst.FALSE) is for use within
 SQL statements, which aren't allowed to use the PL/SQL BOOLEAN datatype.

%param i_val Positive or numerical decimal number. Formatted numbers with
             commas and decimals are fine. Formatted numbers with $ and - (in 
             the middle like with SSN numbers, are not handled automatically. 
             These will register as str.

%return TRUE or 1 if the value is a number. FALSE or 0 if the value is not a number.
------------------------------------------------------------------------------*/
FUNCTION IaNb (i_val IN VARCHAR2) RETURN BOOLEAN;
FUNCTION IaN (i_val IN VARCHAR2) RETURN INTEGER;

/**-----------------------------------------------------------------------------
is_odd:
 Returns true if the number is odd, false if it is even.

%design
 The suffix at the end of each version indicates the type returned by the function.
 The version which returns a number (using cnst.TRUE and cnst.FALSE) is for use within
 SQL statements, which aren't allowed to use the PL/SQL BOOLEAN datatype.

%usage
 <code>
   IF ( num.is_odd(i_list.COUNT) ) THEN...
 </code>

%param    i_num  Number to check

%return TRUE or 1 if the value is odd. FALSE or 0 if the value is even. 
        NULL if the value is null.
------------------------------------------------------------------------------*/
FUNCTION is_oddb (
 i_num  IN NUMBER  
)  RETURN BOOLEAN;
FUNCTION is_odd (
 i_num  IN NUMBER  
)  RETURN NUMBER;

/**-----------------------------------------------------------------------------
is_even:
 Returns true if the number is even, false if it is odd.

%design
 The suffix at the end of each version indicates the type returned by the function.
 The version which returns a number (using cnst.TRUE and cnst.FALSE) is for use within
 SQL statements, which aren't allowed to use the PL/SQL BOOLEAN datatype.

%usage
 <code>
   IF ( num.is_even(i_list.COUNT) ) THEN...
 </code>

%param i_num  Number to check

%return TRUE or 1 if the value is even. FALSE or 0 if the value is odd.
        NULL if the value is null.
------------------------------------------------------------------------------*/
FUNCTION is_evenb  (
 i_num  IN NUMBER
)  RETURN BOOLEAN;    
FUNCTION is_even  (
 i_num  IN NUMBER
)  RETURN NUMBER;    

/**-----------------------------------------------------------------------------
to_base:
 From Tom Kyte. Returns a regular number converted into a particular base value, 
 the most common being base 2 (binary), 10 (decimal), 16 (hexadecimal) and 
 64 (used for uuencoding).
 
%usage
%param i_dec The decimal number to be converted.
%param i_base The base in which the number is to be represented.

%return NULL if either i_dec or i_base is NULL, a string otherwise
------------------------------------------------------------------------------*/
FUNCTION to_base
(
   i_dec  IN NUMBER,
   i_base IN NUMBER
) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
to_dec:
 From Tom Kyte. Returns a regular number converted from a string of binary digits.
 
%usage
%param i_str The binary string to be converted, like '1001101', etc.
%param i_from_base The base in which the decimal number is represented. Default is base 16.

%return NULL if either i_dec or i_base is NULL, a NUMBER otherwise
------------------------------------------------------------------------------*/
FUNCTION to_dec
(
   i_str       IN VARCHAR2,
   i_from_base IN NUMBER DEFAULT 16
) RETURN NUMBER;

/**-----------------------------------------------------------------------------
bin_to_dec:
 Assumes the caller is passing string filled with bits flipped on and off. Converts
 the bitwise/binary string to its base-10 (decimal) representation.
 
%param i_str The binary string to be converted, like '1001101', etc.

%return NULL if i_str is NULL, a NUMBER otherwise
------------------------------------------------------------------------------*/
FUNCTION bin_to_dec(i_str IN VARCHAR2) RETURN NUMBER;

/**-----------------------------------------------------------------------------
to_hex:
 From Tom Kyte. Returns a regular number converted to hexadecimal. This function
 was necessary prior to 10g. Now TO_CHAR can convert to hex using the XXXX format
 mask. Requires to_base to function.
 
%usage
%param i_dec The decimal number to be converted.

%return NULL if i_dec is NULL, a string in hexadecimal otherwise
------------------------------------------------------------------------------*/
FUNCTION to_hex(i_dec IN NUMBER) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
to_bin:
 From Tom Kyte. Returns a regular number converted to a binary (base-2) numeric string.
 Requires to_base to function.
 
%usage
%param i_dec The decimal number to be converted.

%return NULL if i_dec is NULL, a string in hexadecimal otherwise
------------------------------------------------------------------------------*/
FUNCTION to_bin(i_dec IN NUMBER) RETURN VARCHAR2;

/**-----------------------------------------------------------------------------
to_oct:
 From Tom Kyte. Returns a regular base-10 number converted to octal.
 Requires to_base to function.
 
%usage
%param i_dec The decimal number to be converted.

%return NULL if i_dec is NULL, a string in octal otherwise
------------------------------------------------------------------------------*/
FUNCTION to_oct(i_dec IN NUMBER) RETURN VARCHAR2;

--------------------------------------------------------------------------------
--                              PUBLIC PROCEDURES
--------------------------------------------------------------------------------

END num;
/
