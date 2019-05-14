CREATE OR REPLACE PACKAGE BODY excp
/*******************************************************************************
%author
Bill Coulam (bcoulam@dbartisans.com)

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
--                 PACKAGE CONSTANTS, VARIABLES, TYPES, EXCEPTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PRIVATE FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                        PUBLIC FUNCTIONS AND PROCEDURES
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
PROCEDURE assert
(
   i_expr       IN BOOLEAN,
   i_msg        IN VARCHAR2,
   i_raise_excp IN BOOLEAN DEFAULT TRUE,
   i_excp_nm    IN VARCHAR2 DEFAULT NULL,
   i_routine_nm IN app_log.routine_nm%TYPE DEFAULT NULL,
   i_line_num   IN app_log.line_num%TYPE DEFAULT NULL
) IS
   l_routine_nm  app_log.routine_nm%TYPE := i_routine_nm;
   l_line_num    app_log.line_num%TYPE := i_line_num;
BEGIN
   -- We don't worry about location and line number if the caller wanted an
   -- exception to be raised. This is because the exception itself will come
   -- with its own call stack that will indicate which routine contained the
   -- assertion.
   IF (i_raise_excp = FALSE AND i_routine_nm IS NULL) THEN
      DECLARE
         l_unit_nm     user_objects.object_name%TYPE;
         l_owner       typ.t_maxobjnm;
         l_caller_type user_objects.object_type%TYPE;
      BEGIN
         env.caller_meta(l_owner, l_caller_type, l_unit_nm, l_routine_nm, l_line_num, 2);
      END;
   END IF;
   

   IF (NOT NVL(i_expr, FALSE)) THEN
      IF (i_raise_excp) THEN
         IF (i_excp_nm IS NOT NULL) THEN
            EXECUTE IMMEDIATE 'BEGIN'||
                              '   RAISE ' || i_excp_nm || ';'||
                              'END;';
         ELSE
            RAISE_APPLICATION_ERROR(-20000, i_msg);
         END IF;
      ELSE
         -- We replicate some functionality of the MSGS package here because
         -- the EXCP package was meant to be very low level, dependent on nothing.
         dbms_output.put_line(cnst.error || cnst.sepchar || '(Assertion Failure) ' ||
                              '['||l_routine_nm||' line '||NVL(TO_CHAR(l_line_num),'?')||'] '|| i_msg);
         app_log_api.ins('Assertion Failure: '||i_msg, cnst.error, l_routine_nm, l_line_num);
      END IF; -- if exception is provided
   
   END IF; -- if expression is false

END assert;

--------------------------------------------------------------------------------
PROCEDURE throw
(
   i_msg_id IN INTEGER DEFAULT SQLCODE,
   i_msg IN VARCHAR2 DEFAULT SQLERRM
)
IS
   l_msg typ.t_maxvc2;
BEGIN
   -- If throw() is called without a message when a real exception has not 
   -- occurred, the default SQLERRM will be "ORA-0000: normal, successful completion"
   -- which is useless, so we'll try to look up a canned message using the
   -- msg_id.
   IF (i_msg IS NULL OR i_msg LIKE 'ORA-0000:%') THEN
         l_msg := 'Unknown error.';
   ELSE
      l_msg := i_msg;
   END IF;
   
   -- if user-defined in Oracle-provided range
   IF (i_msg_id BETWEEN -20999 AND -20000) THEN
   
      RAISE_APPLICATION_ERROR(i_msg_id, SUBSTR(l_msg,1,2048),TRUE); -- 3rd parm puts the UDE on the stack

   -- if user-defined positive error from APP_MSG table
   ELSIF ((i_msg_id >= 0 AND i_msg_id <> 100)) THEN
      -- UDE = User Defined Error ID
      RAISE_APPLICATION_ERROR(-20000, SUBSTR('UDE['||i_msg_id||'] '||l_msg,1,2048),TRUE);
   
   -- if no data found (can't be bound to local)
   ELSIF (i_msg_id IN (100,-1403) )THEN
   
      RAISE NO_DATA_FOUND;
   
   -- If not positive, user-defined or one of the special no_data_found
   -- exceptions, it must be an Oracle built-in error. So re-raise as-is.
   ELSE
      EXECUTE IMMEDIATE
      'DECLARE'||
      '   lx EXCEPTION;'||
      '   PRAGMA EXCEPTION_INIT(lx,'||TO_CHAR(i_msg_id)||');'||
      'BEGIN'||
      '   RAISE lx;'||
      'END;'
      ;
   END IF;
END throw;

END excp;
/
