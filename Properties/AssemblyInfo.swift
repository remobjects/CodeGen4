﻿import System.Reflection
import System.Runtime.CompilerServices
import System.Runtime.InteropServices

// General Information about an assembly is controlled through the following
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
@assembly:AssemblyTitle("$rootnamespace$")
@assembly:AssemblyDescription("")
@assembly:AssemblyConfiguration("")
@assembly:AssemblyCompany("RemObjects Software")
@assembly:AssemblyProduct("$rootnamespace$")
@assembly:AssemblyCopyright("Copyright © RemObjects Software 2015")
@assembly:AssemblyTrademark("")
@assembly:AssemblyCulture("")

// Setting ComVisible to false makes the types in this assembly not visible
// to COM components.  If you need to access a type in this assembly from
// COM, set the ComVisible attribute to true on that type.
@assembly:ComVisible(false)

// The following GUID is for the ID of the typelib if this project is exposed to COM
@assembly:Guid("2C3408F4-2270-4310-9A38-6A5296129576")

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version
//      Build Number
//      Revision
//
@assembly:AssemblyVersion("1.0.0.0")
@assembly:AssemblyFileVersion("1.0.0.0")

// In order to sign your assembly you must specify a key to use. Refer to the
// Microsoft .NET Framework documentation for more information on assembly signing.
//
// Use the attributes below to control which key is used for signing.
//
// Notes:
//   (*) If no key is specified, the assembly is not signed.
//   (*) KeyName refers to a key that has been installed in the Crypto Service
//       Provider (CSP) on your machine. KeyFile refers to a file which contains
//       a key.
//   (*) If the KeyFile and the KeyName values are both specified, the
//       following processing occurs:
//       (1) If the KeyName can be found in the CSP, that key is used.
//       (2) If the KeyName does not exist and the KeyFile does exist, the key
//           in the KeyFile is installed into the CSP and used.
//   (*) In order to create a KeyFile, you can use the sn.exe (Strong Name) utility.
//       When specifying the KeyFile, the location of the KeyFile should be
//       relative to the project output directory, which in Oxygene by default is the
//       same as the project directory. For example, if your KeyFile is
//       located in the project directory, you would specify the AssemblyKeyFile
//       attribute as @assembly:AssemblyKeyFile('mykey.snk')
//   (*) Delay Signing is an advanced option - see the Microsoft .NET Framework
//       documentation for more information on this.
//
@assembly:AssemblyDelaySign(false)
@assembly:AssemblyKeyFile("")
@assembly:AssemblyKeyName("")