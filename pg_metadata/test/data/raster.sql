BEGIN;
CREATE TABLE "pgmetadata"."raster" ("rid" serial PRIMARY KEY,"rast" raster);
INSERT INTO "pgmetadata"."raster" ("rast") VALUES ('0100000100000000000000594000000000000059C000000000804F12410000000030BF554100000000000000000000000000000000E9640000080008004AEEFFFF7E359CFEBEBE6505BFC7020BBF759A0CBF3BA30BBF149609BFEA1C09BF61520DBFFDDD06BFE1DC0CBFBB5515BFEBF518BFE38C17BF7CDA12BF28CF0DBFE1C911BF0A8911BFD93417BFD2B924BFFD7D29BF06B126BFEA8A1FBFBA4D18BF695419BF717726BFF91032BFA16A3DBF284240BF879A39BF27192FBF971E27BF165F24BFB9963ABF5A6F4DBFC1825CBFF81C5DBFB7504EBF479E3CBF28E432BF39C32EBFA2F647BFF0C163BFB66B7FBF32C17FBFD3FD61BF944E42BFA7EE3BBFC50638BF025049BFAD1E68BF37228DBF50FA8EBF04096FBFD1964FBF672645BFC9BA3FBFA2F647BF0BF160BF40AD7FBF96FC7EBF165461BF944E42BFA7EE3BBF2B6D1EBF'::raster);
SELECT AddRasterConstraints('pgmetadata','raster','rast',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,TRUE);
END;