#!/usr/bin/env luajit

local ffi = require('ffi')
local xml2 = ffi.load('xml2')

ffi.cdef[[

/* xmlstring.h */

typedef unsigned char xmlChar;

/* tree.h */

typedef struct _xmlDoc xmlDoc;
typedef xmlDoc *xmlDocPtr;

/* parser.h */

/* XMLPUBFUN */ xmlDocPtr /* XMLCALL */
		xmlParseDoc		(const xmlChar *cur);

/* xmlschemas.h */

typedef struct _xmlSchemaParserCtxt xmlSchemaParserCtxt;
typedef xmlSchemaParserCtxt *xmlSchemaParserCtxtPtr;

typedef struct _xmlSchemaValidCtxt xmlSchemaValidCtxt;
typedef xmlSchemaValidCtxt *xmlSchemaValidCtxtPtr;

/* XMLPUBFUN */ xmlSchemaParserCtxtPtr /* XMLCALL */
	    xmlSchemaNewParserCtxt	(const char *URL);

typedef struct _xmlSchema xmlSchema;
typedef xmlSchema *xmlSchemaPtr;

/* XMLPUBFUN */ xmlSchemaPtr /* XMLCALL */
	    xmlSchemaParse		(xmlSchemaParserCtxtPtr ctxt);

/* XMLPUBFUN */ xmlSchemaValidCtxtPtr /* XMLCALL */
	    xmlSchemaNewValidCtxt	(xmlSchemaPtr schema);
/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaFreeValidCtxt	(xmlSchemaValidCtxtPtr ctxt);

/* XMLPUBFUN */ void /* XMLCALL */
            xmlSchemaValidateSetFilename(xmlSchemaValidCtxtPtr vctxt,
	                                 const char *filename);

/* XMLPUBFUN */ int /* XMLCALL */
	    xmlSchemaValidateDoc	(xmlSchemaValidCtxtPtr ctxt,
					 xmlDocPtr instance);
]]

function readfile(filename)
    local lines = {}
    for line in io.lines(filename) do
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

local schema = 'saml-schema-protocol-2.0.xsd'
local ctxt = xml2.xmlSchemaNewParserCtxt(schema)
local wxschemas = xml2.xmlSchemaParse(ctxt)
if wxschemas == nil then
    print('failed to parse schema')
    return
end

local vctxt = xml2.xmlSchemaNewValidCtxt(wxschemas)
local filename = 'res-signed.xml'
xml2.xmlSchemaValidateSetFilename(vctxt, filename)
local data = readfile(filename)
local doc = xml2.xmlParseDoc(data)
local ret = xml2.xmlSchemaValidateDoc(vctxt, doc)
print('ret=', ret)
xml2.xmlSchemaFreeValidCtxt(vctxt)
