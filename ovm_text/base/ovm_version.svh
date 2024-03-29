//----------------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
//   Copyright 2007-2009 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

`ifndef OVM_VERSION_SVH
`define OVM_VERSION_SVH

parameter string ovm_mgc_copyright = "(C) 2007-2009 Mentor Graphics Corporation";
parameter string ovm_cdn_copyright = "(C) 2007-2009 Cadence Design Systems, Inc.";

`ifdef VCS
   string ovm_revision = `OVM_VERSION_STRING;
`else
   parameter string ovm_revision = `OVM_VERSION_STRING;
`endif

function string ovm_revision_string();
  return ovm_revision;
endfunction

`endif // OVM_VERSION_SVH
