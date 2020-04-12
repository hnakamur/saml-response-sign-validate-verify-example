#!/usr/bin/env luajit

local ffi = require('ffi')
local xml2 = ffi.load('xml2')

ffi.cdef[[

/******************************************************************************
 * ctype.h
 ******************************************************************************/

int isspace(int c);


/******************************************************************************
 * string.h
 ******************************************************************************/

size_t strlen(const char *s);


/******************************************************************************
 * xmlstring.h
 ******************************************************************************/

typedef unsigned char xmlChar;


/******************************************************************************
 * tree.h
 ******************************************************************************/

typedef struct _xmlDoc xmlDoc;
typedef xmlDoc *xmlDocPtr;


/******************************************************************************
 * parser.h
 ******************************************************************************/

/* XMLPUBFUN */ xmlDocPtr /* XMLCALL */
		xmlParseDoc		(const xmlChar *cur);


/******************************************************************************
 * xmlerror.h
 ******************************************************************************/

/**
 * xmlErrorLevel:
 *
 * Indicates the level of an error
 */
typedef enum {
    XML_ERR_NONE = 0,
    XML_ERR_WARNING = 1,	/* A simple warning */
    XML_ERR_ERROR = 2,		/* A recoverable error */
    XML_ERR_FATAL = 3		/* A fatal error */
} xmlErrorLevel;

/**
 * xmlError:
 *
 * An XML Error instance.
 */

typedef struct _xmlError xmlError;
typedef xmlError *xmlErrorPtr;
struct _xmlError {
    int		domain;	/* What part of the library raised this error */
    int		code;	/* The error code, e.g. an xmlParserError */
    char       *message;/* human-readable informative error message */
    xmlErrorLevel level;/* how consequent is the error */
    char       *file;	/* the filename */
    int		line;	/* the line number if available */
    char       *str1;	/* extra string information */
    char       *str2;	/* extra string information */
    char       *str3;	/* extra string information */
    int		int1;	/* extra number information */
    int		int2;	/* error column # or 0 if N/A (todo: rename field when we would brk ABI) */
    void       *ctxt;   /* the parser context if available */
    void       *node;   /* the node in the tree */
};

/**
 * xmlStructuredErrorFunc:
 * @userData:  user provided data for the error callback
 * @error:  the error being raised.
 *
 * Signature of the function to use when there is an error and
 * the module handles the new error reporting mechanism.
 */
typedef void (/* XMLCALL */ *xmlStructuredErrorFunc) (void *userData, xmlErrorPtr error);

/* XMLPUBFUN */ void /* XMLCALL */
    xmlSetStructuredErrorFunc	(void *ctx,
				 xmlStructuredErrorFunc handler);

/******************************************************************************
 * xmlschemas.h
 ******************************************************************************/

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

/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaSetParserStructuredErrors(xmlSchemaParserCtxtPtr ctxt,
					 xmlStructuredErrorFunc serror,
					 void *ctx);

/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaSetValidStructuredErrors(xmlSchemaValidCtxtPtr ctxt,
					 xmlStructuredErrorFunc serror,
					 void *ctx);
]]

function readfile(filename)
    local lines = {}
    for line in io.lines(filename) do
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

local function ffiStr(cdata, def_val)
    if cdata == nil then
        return def_val or ''
    end
    return ffi.string(cdata)
end

local function ffiStrTrimRight(cdata, def_val)
    if cdata == nil then
        return def_val or ''
    end
    local len = ffi.C.strlen(cdata) - 1
    while len > 0 and ffi.C.isspace(cdata[len]) ~= 0 do
        len = len - 1
    end
    return ffi.string(cdata, len + 1)
end

local function errFileLine(err)
    if err.file == nil then
        return ''
    end
    if err.line == 0 then
        return ffi.string(err.file)
    end
    return ffi.string(err.file) .. ':' .. tostring(err.line)
end

local function globalParseError(userData, err)
    local msg = ffiStrTrimRight(err.message)
    local fileLine = errFileLine(err)
    if fileLine ~= "" then
        msg = fileLine .. ': ' .. msg
    end
    print(string.format('parseError: %s', msg))
end
xml2.xmlSetStructuredErrorFunc(nil, globalParseError)

local schema = 'saml-schema-protocol-2.0.xsd'
local ctxt = xml2.xmlSchemaNewParserCtxt(schema)
local parseErrMsg
local function parseError(userData, err)
    local msg = ffiStrTrimRight(err.message)
    local fileLine = errFileLine(err)
    if fileLine ~= "" then
        msg = fileLine .. ': ' .. msg
    end
    parseErrMsg = msg
end
xml2.xmlSchemaSetParserStructuredErrors(ctxt, parseError, nil)
local wxschemas = xml2.xmlSchemaParse(ctxt)
if wxschemas == nil then
    print(string.format("schema parse error, message=%s", parseErrMsg))
    return
end

local vctxt = xml2.xmlSchemaNewValidCtxt(wxschemas)
local validateErrMsg
local function validateError(dst, err)
    local msg = ffiStrTrimRight(err.message)
    local fileLine = errFileLine(err)
    if fileLine ~= "" then
        msg = fileLine .. ': ' .. msg
    end
    validateErrMsg = msg
end
xml2.xmlSchemaSetValidStructuredErrors(vctxt, validateError, nil)
local filename = 'res-signed.xml'
xml2.xmlSchemaValidateSetFilename(vctxt, filename)
local data = readfile(filename)
local doc = xml2.xmlParseDoc(data)
local ret = xml2.xmlSchemaValidateDoc(vctxt, doc)
if ret ~= 0 then
    print(string.format("validate error, ret=%d, message=%s", ret, validateErrMsg))
else
    print('validate OK!')
end
xml2.xmlSchemaFreeValidCtxt(vctxt)
