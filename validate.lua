#!/usr/bin/env luajit

local ffi = require('ffi')
local xml2 = ffi.load('xml2')

ffi.cdef[[

/* encoding.h */

typedef enum {
    XML_CHAR_ENCODING_ERROR=   -1, /* No char encoding detected */
    XML_CHAR_ENCODING_NONE=	0, /* No char encoding detected */
    XML_CHAR_ENCODING_UTF8=	1, /* UTF-8 */
    XML_CHAR_ENCODING_UTF16LE=	2, /* UTF-16 little endian */
    XML_CHAR_ENCODING_UTF16BE=	3, /* UTF-16 big endian */
    XML_CHAR_ENCODING_UCS4LE=	4, /* UCS-4 little endian */
    XML_CHAR_ENCODING_UCS4BE=	5, /* UCS-4 big endian */
    XML_CHAR_ENCODING_EBCDIC=	6, /* EBCDIC uh! */
    XML_CHAR_ENCODING_UCS4_2143=7, /* UCS-4 unusual ordering */
    XML_CHAR_ENCODING_UCS4_3412=8, /* UCS-4 unusual ordering */
    XML_CHAR_ENCODING_UCS2=	9, /* UCS-2 */
    XML_CHAR_ENCODING_8859_1=	10,/* ISO-8859-1 ISO Latin 1 */
    XML_CHAR_ENCODING_8859_2=	11,/* ISO-8859-2 ISO Latin 2 */
    XML_CHAR_ENCODING_8859_3=	12,/* ISO-8859-3 */
    XML_CHAR_ENCODING_8859_4=	13,/* ISO-8859-4 */
    XML_CHAR_ENCODING_8859_5=	14,/* ISO-8859-5 */
    XML_CHAR_ENCODING_8859_6=	15,/* ISO-8859-6 */
    XML_CHAR_ENCODING_8859_7=	16,/* ISO-8859-7 */
    XML_CHAR_ENCODING_8859_8=	17,/* ISO-8859-8 */
    XML_CHAR_ENCODING_8859_9=	18,/* ISO-8859-9 */
    XML_CHAR_ENCODING_2022_JP=  19,/* ISO-2022-JP */
    XML_CHAR_ENCODING_SHIFT_JIS=20,/* Shift_JIS */
    XML_CHAR_ENCODING_EUC_JP=   21,/* EUC-JP */
    XML_CHAR_ENCODING_ASCII=    22 /* pure ASCII */
} xmlCharEncoding;

/* xmlstring.h */

typedef unsigned char xmlChar;

/* tree.h */

typedef struct _xmlDoc xmlDoc;
typedef xmlDoc *xmlDocPtr;

typedef struct _xmlParserInputBuffer xmlParserInputBuffer;
typedef xmlParserInputBuffer *xmlParserInputBufferPtr;

typedef struct _xmlSAXHandler xmlSAXHandler;
typedef xmlSAXHandler *xmlSAXHandlerPtr;

/* parser.h */

/* XMLPUBFUN */ xmlDocPtr /* XMLCALL */
		xmlParseDoc		(const xmlChar *cur);

/* #define XML_SAX2_MAGIC 0xDEEDBEAF */
static const unsigned int XML_SAX2_MAGIC = 0xDEEDBEAF;

struct _xmlSAXHandler {
    /* NOTE: I'm lazy here to use void * instead of xxxFunc. */
    void * /* internalSubsetSAXFunc */ internalSubset;
    void * /* isStandaloneSAXFunc */ isStandalone;
    void * /* hasInternalSubsetSAXFunc */ hasInternalSubset;
    void * /* hasExternalSubsetSAXFunc */ hasExternalSubset;
    void * /* resolveEntitySAXFunc */ resolveEntity;
    void * /* getEntitySAXFunc */ getEntity;
    void * /* entityDeclSAXFunc */ entityDecl;
    void * /* notationDeclSAXFunc */ notationDecl;
    void * /* attributeDeclSAXFunc */ attributeDecl;
    void * /* elementDeclSAXFunc */ elementDecl;
    void * /* unparsedEntityDeclSAXFunc */ unparsedEntityDecl;
    void * /* setDocumentLocatorSAXFunc */ setDocumentLocator;
    void * /* startDocumentSAXFunc */ startDocument;
    void * /* endDocumentSAXFunc */ endDocument;
    void * /* startElementSAXFunc */ startElement;
    void * /* endElementSAXFunc */ endElement;
    void * /* referenceSAXFunc */ reference;
    void * /* charactersSAXFunc */ characters;
    void * /* ignorableWhitespaceSAXFunc */ ignorableWhitespace;
    void * /* processingInstructionSAXFunc */ processingInstruction;
    void * /* commentSAXFunc */ comment;
    void * /* warningSAXFunc */ warning;
    void * /* errorSAXFunc */ error;
    void * /* fatalErrorSAXFunc */ fatalError; /* unused error() get all the errors */
    void * /* getParameterEntitySAXFunc */ getParameterEntity;
    void * /* cdataBlockSAXFunc */ cdataBlock;
    void * /* externalSubsetSAXFunc */ externalSubset;
    unsigned int initialized;
    /* The following fields are extensions available only on version 2 */
    void *_private;
    void * /* startElementNsSAX2Func */ startElementNs;
    void * /* endElementNsSAX2Func */ endElementNs;
    void * /* xmlStructuredErrorFunc */ serror;
};

/* xmlIO.h */

/* XMLPUBFUN */ xmlParserInputBufferPtr /* XMLCALL */
	xmlParserInputBufferCreateFilename	(const char *URI,
                                                 xmlCharEncoding enc);
xmlParserInputBufferPtr
	__xmlParserInputBufferCreateFilename(const char *URI,
						xmlCharEncoding enc);

/* XMLPUBFUN */ xmlParserInputBufferPtr /* XMLCALL */
	xmlParserInputBufferCreateStatic	(const char *mem, int size,
	                                         xmlCharEncoding enc);
/* XMLPUBFUN */ void /* XMLCALL */
	xmlFreeParserInputBuffer		(xmlParserInputBufferPtr in);

/* xmlschemas.h */

typedef struct _xmlSchemaParserCtxt xmlSchemaParserCtxt;
typedef xmlSchemaParserCtxt *xmlSchemaParserCtxtPtr;

typedef struct _xmlSchemaValidCtxt xmlSchemaValidCtxt;
typedef xmlSchemaValidCtxt *xmlSchemaValidCtxtPtr;

/* XMLPUBFUN */ xmlSchemaParserCtxtPtr /* XMLCALL */
	    xmlSchemaNewParserCtxt	(const char *URL);

typedef void (/* XMLCDECL */ *xmlGenericErrorFunc) (void *ctx,
				 const char *msg,
				 ...) /* LIBXML_ATTR_FORMAT(2,3) */;

/* XMLPUBFUN */ xmlGenericErrorFunc * /* XMLCALL */ __xmlGenericError(void);
// #ifdef LIBXML_THREAD_ENABLED
// #define xmlGenericError \
// (*(__xmlGenericError()))
// #else
// XMLPUBVAR xmlGenericErrorFunc xmlGenericError;
// #endif

typedef void (/* XMLCDECL */ *xmlSchemaValidityErrorFunc)
                 (void *ctx, const char *msg, ...) /* LIBXML_ATTR_FORMAT(2,3) */;
typedef void (/* XMLCDECL */ *xmlSchemaValidityWarningFunc)
                 (void *ctx, const char *msg, ...) /* LIBXML_ATTR_FORMAT(2,3) */;

/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaSetParserErrors	(xmlSchemaParserCtxtPtr ctxt,
					 xmlSchemaValidityErrorFunc err,
					 xmlSchemaValidityWarningFunc warn,
					 void *ctx);

typedef struct _xmlSchema xmlSchema;
typedef xmlSchema *xmlSchemaPtr;

/* XMLPUBFUN */ xmlSchemaPtr /* XMLCALL */
	    xmlSchemaParse		(xmlSchemaParserCtxtPtr ctxt);

/* XMLPUBFUN */ xmlSchemaValidCtxtPtr /* XMLCALL */
	    xmlSchemaNewValidCtxt	(xmlSchemaPtr schema);
/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaFreeValidCtxt	(xmlSchemaValidCtxtPtr ctxt);

/* XMLPUBFUN */ void /* XMLCALL */
	    xmlSchemaSetValidErrors	(xmlSchemaValidCtxtPtr ctxt,
					 xmlSchemaValidityErrorFunc err,
					 xmlSchemaValidityWarningFunc warn,
					 void *ctx);

/* XMLPUBFUN */ void /* XMLCALL */
            xmlSchemaValidateSetFilename(xmlSchemaValidCtxtPtr vctxt,
	                                 const char *filename);

/* XMLPUBFUN */ int /* XMLCALL */
	    xmlSchemaValidateStream	(xmlSchemaValidCtxtPtr ctxt,
					 xmlParserInputBufferPtr input,
					 xmlCharEncoding enc,
					 xmlSAXHandlerPtr sax,
					 void *user_data);

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

-- print(string.format('xml2.XML_SAX2_MAGIC=%x', xml2.XML_SAX2_MAGIC))

-- local emptySAXHandler = ffi.new('xmlSAXHandler')
-- ffi.fill(emptySAXHandler, ffi.sizeof('xmlSAXHandler'))
-- emptySAXHandler.initialized = xml2.XML_SAX2_MAGIC

local schema = 'saml-schema-protocol-2.0.xsd'
local ctxt = xml2.xmlSchemaNewParserCtxt(schema)
-- print(string.format('ctxt address=%p', ctxt))
local xmlGenericError = xml2.__xmlGenericError()[0]
-- xml2.xmlSchemaSetParserErrors(ctxt, xmlGenericError, xmlGenericError, nil)
local wxschemas = xml2.xmlSchemaParse(ctxt)
if wxschemas == nil then
    print('failed to parse schema')
    return
end

local vctxt = xml2.xmlSchemaNewValidCtxt(wxschemas)
-- xml2.xmlSchemaSetValidErrors(vctxt, xmlGenericError, xmlGenericError, nil)
-- local filename = 'res-signed.xml'
-- xml2.xmlSchemaValidateSetFilename(vctxt, filename)

local data = readfile('res-signed.xml')
local doc = xml2.xmlParseDoc(data)
local ret = xml2.xmlSchemaValidateDoc(vctxt, doc)

-- local buf = xml2.xmlParserInputBufferCreateFilename('res-signed.xml', xml2.XML_CHAR_ENCODING_NONE)
-- -- local buf = xml2.xmlParserInputBufferCreateStatic(data, #data, xml2.XML_CHAR_ENCODING_NONE)
-- -- local buf = xml2.xmlParserInputBufferCreateStatic(data, #data, xml2.XML_CHAR_ENCODING_UTF8)
-- local user_data = nil 
-- local ret = xml2.xmlSchemaValidateStream(vctxt, buf, 0, emptySAXHandler, user_data)
print('ret=', ret)
xml2.xmlSchemaFreeValidCtxt(vctxt)
-- xml2.xmlFreeParserInputBuffer(buf)
