//SPDX-License-Identifier: Licence to kill
pragma solidity ^0.8.0;

import "./IPOWNFTPartial.sol";
import "./IAtomReader.sol";

/// @title POWNFT Atom Reader
/// @author AnAllergyToAnalogy
contract AtomReader is IAtomReader{


    //Simplified version of POWNFT interface, with just the functions needed for this.
    IPOWNFTPartial POWNFT;

    /// @dev Takes POWNFT main contract address as only argument.
    constructor(address mainContract){
        POWNFT = IPOWNFTPartial(mainContract);
    }

    function getAtomData(uint _tokenId) override public view returns(uint atomicNumber, int8 ionCharge){
        bytes32 _hash = POWNFT.hashOf(_tokenId);
        atomicNumber = calculateAtomicNumber(_tokenId, _hash);
        return (
            atomicNumber,
            calculateIonCharge(atomicNumber,_hash)
        );
    }
    function getAtomicNumber(uint _tokenId) override  public view returns(uint){
        bytes32 _hash = POWNFT.hashOf(_tokenId);

        return calculateAtomicNumber(_tokenId,_hash);
    }
    function getIonCharge(uint _tokenId) override public view returns(int8){
        bytes32 _hash = POWNFT.hashOf(_tokenId);
        uint atomicNumber = getAtomicNumber(_tokenId);

        return calculateIonCharge(atomicNumber,_hash);
    }
    function getIons(uint atomicNumber) override public pure returns(int8[] memory){
        int8[] memory ions;

        if(atomicNumber == 1 || atomicNumber == 3 || atomicNumber == 11 || atomicNumber == 19 || atomicNumber == 37 || atomicNumber == 47 || atomicNumber == 55 || atomicNumber == 87){
            ions = new int8[](1);
            ions[0] = 1;

        }else if(atomicNumber == 4 || atomicNumber == 12 || atomicNumber == 20 || atomicNumber == 30 || atomicNumber == 38 || atomicNumber == 48 || atomicNumber == 56 || atomicNumber == 80 ||
            atomicNumber == 88){
            ions = new int8[](1);
            ions[0] = 2;

        }else if(atomicNumber == 13 || atomicNumber == 21 || atomicNumber == 31 || atomicNumber == 39 || atomicNumber == 45 || atomicNumber == 49 || atomicNumber == 57 || atomicNumber == 58 ||
        atomicNumber == 59 || atomicNumber == 60 || atomicNumber == 61 || atomicNumber == 64 || atomicNumber == 65 || atomicNumber == 66 || atomicNumber == 67 || atomicNumber == 68 || atomicNumber == 69 || atomicNumber == 70 || atomicNumber == 71 || atomicNumber == 89 || atomicNumber == 96 || atomicNumber == 97 || atomicNumber == 98 || atomicNumber == 99 || atomicNumber ==
        100 || atomicNumber == 103){
            ions = new int8[](1);
            ions[0] = 3;

        }else if(atomicNumber == 32 || atomicNumber == 40 || atomicNumber == 72 || atomicNumber == 76 || atomicNumber == 77 || atomicNumber == 90 || atomicNumber == 94){
            ions = new int8[](1);
            ions[0] = 4;

        }else if(atomicNumber == 73 || atomicNumber == 93){
            ions = new int8[](1);
            ions[0] = 5;

        }else if(atomicNumber == 42 || atomicNumber == 74){
            ions = new int8[](1);
            ions[0] = 6;

        }else if(atomicNumber == 43 || atomicNumber == 75){
            ions = new int8[](1);
            ions[0] = 7;

        }else if(atomicNumber == 7 || atomicNumber == 15 || atomicNumber == 33){
            ions = new int8[](1);
            ions[0] = -3;

        }else if(atomicNumber == 8 || atomicNumber == 16 || atomicNumber == 34 || atomicNumber == 52){
            ions = new int8[](1);
            ions[0] = -2;

        }else if(atomicNumber == 9 || atomicNumber == 17 || atomicNumber == 35 || atomicNumber == 53 || atomicNumber == 85){
            ions = new int8[](1);
            ions[0] = -1;

        }else if(atomicNumber == 22 || atomicNumber == 44 || atomicNumber == 95){
            ions = new int8[](2);
            ions[0] = 3;
            ions[1] = 4;

        }else if(atomicNumber == 23 || atomicNumber == 41 || atomicNumber == 51 || atomicNumber == 83){
            ions = new int8[](2);
            ions[0] = 3;
            ions[1] = 5;

        }else if(atomicNumber == 24 || atomicNumber == 26 || atomicNumber == 27 || atomicNumber == 28 || atomicNumber == 62 || atomicNumber == 63 || atomicNumber == 101 || atomicNumber == 102){
            ions = new int8[](2);
            ions[0] = 2;
            ions[1] = 3;

        }else if(atomicNumber == 25 || atomicNumber == 46 || atomicNumber == 50 || atomicNumber == 78 || atomicNumber == 82 || atomicNumber == 84){
            ions = new int8[](2);
            ions[0] = 2;
            ions[1] = 4;

        }else if(atomicNumber == 29){
            ions = new int8[](2);
            ions[0] = 1;
            ions[1] = 2;

        }else if(atomicNumber == 79 || atomicNumber == 81){
            ions = new int8[](2);
            ions[0] = 1;
            ions[1] = 3;

        }else if(atomicNumber == 91){
            ions = new int8[](2);
            ions[0] = 4;
            ions[1] = 5;

        }else if(atomicNumber == 92){
            ions = new int8[](2);
            ions[0] = 4;
            ions[1] = 6;
        }
        return ions;
    }
    function isValidIonCharge(uint atomicNumber, int8 ionCharge) override public pure returns(bool){
        int8[] memory ions = getIons(atomicNumber);

        for(uint i = 0; i < ions.length; i++){
            if(ions[i] == ionCharge){
                return true;
            }
        }
        return false;
    }
    function canIonise(uint atomicNumber) override public pure returns(bool){
        int8[] memory ions = getIons(atomicNumber);
        return ions.length > 0;
    }

    /// @notice Calculate generation of specified Atom
    /// @param _tokenId TokenId of the Atom
    /// @return generation Generation of the Atom
    function generationOf(uint _tokenId) private pure returns(uint generation){
        for(generation = 0; _tokenId > 0; generation++){
            _tokenId /= 2;
        }
        return generation - 1;
    }

    /// @notice Round up to calculate "ceil".
    /// @dev Because the metadata uses Javascript's Math.ceil
    /// @param a Number to round
    /// @param m Round up to the nearest 'm'
    /// @return Rounded up 'a'
    function ceil(uint a, uint m) internal pure returns (uint ) {
        return ((a + m - 1) / m) * m;
    }

    /// @notice Calculate ionic charge for a given Element and token hash
    /// @dev The reason it needs both is that atomic number is partially based on tokenId, so just passing the hash would require recalculation in instances where it wasn't necessary.
    /// @param atomicNumber Atomic number of Element
    /// @param _hash Hash of Atom
    /// @return Ionic charge for given Element for specified hash
    function calculateIonCharge(uint atomicNumber, bytes32 _hash) private pure returns(int8){
        bytes32 divisor1 = 0x0000000000010000000000000000000000000000000000000000000000000000;
        uint salt1 = uint(_hash)/uint(divisor1);
        salt1 %= 256;

        if(salt1 % 3 != 0){
            return 0;
        }

        bytes32 divisor2 = 0x0000000000000100000000000000000000000000000000000000000000000000;
        uint salt2 = uint(_hash)/uint(divisor2);
        salt2 %= 256;

        int8[] memory ions = getIons(atomicNumber);


        if(ions.length == 0) return 0;

        uint ion_index = salt2%ions.length;

        return ions[ion_index];

    }

    /// @notice Calculate atomic number for a given tokenId and token hash
    /// @dev The reason it needs both is that atomic number is partially based on tokenId.
    /// @param _tokenId The tokenId of the Atom
    /// @param _hash Hash of Atom
    /// @return Atomic number of the given Atom
    function calculateAtomicNumber(uint _tokenId, bytes32 _hash) private pure returns(uint){
        if(_tokenId == 1) return 0;

        bytes32 divisor = 0x0000000001000000000000000000000000000000000000000000000000000000;
        uint salt = uint(_hash)/uint(divisor);

        //                    0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC;
        uint generation = generationOf(_tokenId);
        uint max;
        if(generation >= 13){
            max = 118;
        }else if(generation >= 11){
            max = 86;
        }else if(generation >= 9){
            max = 54;
        }else if(generation >= 7){
            max = 36;
        }else if(generation >= 5){
            max = 18;
        }else if(generation >= 3){
            max = 10;
        }else if(generation >= 1){
            max = 2;
        }

        uint gg;
        if(generation >= 8){
            gg = 2;
        }else{
            gg = 1;
        }


        uint decimal = 10000000000000000;
        uint divisor2 = uint(0xFFFFFFFFFF);


        uint unrounded = max * decimal * (salt ** gg) / (divisor2 ** gg);
        uint rounded = ceil(
            unrounded,
            decimal
        );
        return rounded/decimal;
    }
}