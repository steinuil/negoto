#pragma once

#include <urweb.h>

uw_Basis_string uw_FileFfi_md5Hash(uw_context, uw_Basis_file);

uw_unit uw_FileFfi_mkdir(uw_context, uw_Basis_string);
uw_unit uw_FileFfi_save(uw_context, uw_Basis_string section, uw_Basis_string name, uw_Basis_file);
uw_unit uw_FileFfi_delete(uw_context, uw_Basis_string section, uw_Basis_string name);
uw_Basis_string uw_FileFfi_link(uw_context, uw_Basis_string section, uw_Basis_string name);
uw_unit uw_FileFfi_saveImage(uw_context, uw_Basis_string section, uw_Basis_string thumb_section, uw_Basis_string fname, uw_Basis_string hash, uw_Basis_file);
