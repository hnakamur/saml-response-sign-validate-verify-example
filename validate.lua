#!/usr/bin/env luajit

local ffi = require('ffi')
local C = ffi.C
local xml2 = ffi.load('xml2')

ffi.cdef[[

typedef struct {
    const char *data;
    int len;
    int pos;
} xsdReadContext, *xsdReadContextPtr;

/******************************************************************************
 * ctype.h
 ******************************************************************************/

int isspace(int c);


/******************************************************************************
 * string.h
 ******************************************************************************/

size_t strlen(const char *s);
char *basename(const char *filename);


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

/**
 * xmlInputMatchCallback:
 * @filename: the filename or URI
 *
 * Callback used in the I/O Input API to detect if the current handler
 * can provide input fonctionnalities for this resource.
 *
 * Returns 1 if yes and 0 if another Input module should be used
 */
typedef int (/* XMLCALL */ *xmlInputMatchCallback) (char const *filename);
/**
 * xmlInputOpenCallback:
 * @filename: the filename or URI
 *
 * Callback used in the I/O Input API to open the resource
 *
 * Returns an Input context or NULL in case or error
 */
typedef void * (/* XMLCALL */ *xmlInputOpenCallback) (char const *filename);
/**
 * xmlInputReadCallback:
 * @context:  an Input context
 * @buffer:  the buffer to store data read
 * @len:  the length of the buffer in bytes
 *
 * Callback used in the I/O Input API to read the resource
 *
 * Returns the number of bytes read or -1 in case of error
 */
typedef int (/* XMLCALL */ *xmlInputReadCallback) (void * context, char * buffer, int len);
/**
 * xmlInputCloseCallback:
 * @context:  an Input context
 *
 * Callback used in the I/O Input API to close the resource
 *
 * Returns 0 or -1 in case of error
 */
typedef int (/* XMLCALL */ *xmlInputCloseCallback) (void * context);

/* XMLPUBFUN */ int /* XMLCALL */
	xmlRegisterInputCallbacks		(xmlInputMatchCallback matchFunc,
						 xmlInputOpenCallback openFunc,
						 xmlInputReadCallback readFunc,
						 xmlInputCloseCallback closeFunc);

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

local function has_suffix(s, suffix)
    return #s >= #suffix and string.sub(s, -#suffix) == suffix
end

local xsdFiles = {}
local function loadXsdFiles(filenames)
    for _, filename in ipairs(filenames) do
        xsdFiles[filename] = readfile(filename)
    end
end

local function xsdMatch(filename)
    local filename_s = ffi.string(filename)
    if has_suffix(filename_s, '.xsd') then
        -- print('xsdMatch, filename=', filename_s, ', returns 1')
        return 1
    end
    return 0
end

local function xsdOpen(filename)
    local filename_s = ffi.string(C.basename(filename))
    local data = xsdFiles[filename_s]
    if data == nil then
        return nil
    end
    local context = ffi.new('xsdReadContext[1]')
    context[0].data = data
    context[0].len = #data
    context[0].pos = 0
    return context
end

local function xsdRead(context, buffer, len)
    if context == nil then
        return -1
    end
    local ctx = ffi.cast('xsdReadContextPtr', context)
    local to_copy = ctx.len - ctx.pos
    if to_copy >= len then
        to_copy = len
    end
    -- print('xsdRead, pos=', ctx.pos, ', to_copy=', to_copy, ', len=', len, ', ctx.len=', ctx.len)
    ffi.copy(buffer, ctx.data + ctx.pos, to_copy)
    ctx.pos = ctx.pos + to_copy
    return to_copy
end

local  function xsdClose(context)
    return 0
end

if xml2.xmlRegisterInputCallbacks(xsdMatch, xsdOpen, xsdRead, xsdClose) ~= 0 then
    print('error in xmlRegisterInputCallbacks')
end
loadXsdFiles{
    'saml-schema-assertion-2.0.xsd',
    'saml-schema-protocol-2.0.xsd',
    'xenc-schema.xsd',
    'xmldsig-core-schema.xsd',
}
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
