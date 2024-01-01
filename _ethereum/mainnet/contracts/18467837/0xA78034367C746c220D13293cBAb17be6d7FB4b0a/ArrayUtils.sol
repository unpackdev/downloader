// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

library ArrayUtils {

    function merge(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns(uint256[] memory)
    {
        uint256[] memory arrC = new uint256[](arrA.length + arrB.length);
        uint256 lenC;

        (arrC, lenC) = filter(arrA, arrC, 0);
        (arrC, lenC) = filter(arrB, arrC, lenC);

        return resize(arrC, lenC);
    }

    function filter(uint256[] memory arrA, uint256[] memory arrC, uint256 lenC) 
        public pure returns(uint256[] memory, uint256)
    {
        uint256 lenA = arrA.length;
        uint256 i;
        
        while (i < lenA) {
        
            uint256 j;
            while (j < lenC){
                if (arrA[i] == arrC[j]) break;
                j++;
            }

            if (j == lenC) {
                arrC[lenC] = arrA[i];
                lenC++;
            }

            i++;
        }

        return (arrC, lenC);
    }

    function refine(uint256[] memory arrA) 
        public pure returns(uint256[] memory)
    {
        uint256[] memory arrB = new uint256[](arrA.length);        
        uint256 lenB;
        (arrB, lenB) = filter(arrA, arrB, 0);

        return resize(arrB, lenB);
    }

    function resize(uint256[] memory arrA, uint256 len)
        public pure returns(uint256[] memory)
    {
        uint256[] memory output = new uint256[](len);

        while (len > 0) {
            output[len - 1] = arrA[len - 1];
            len--;
        }
        // assembly {
        //     output := arrA
        // }
        return output;
    }


    function combine(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;
        uint256 i;

        uint256[] memory arrC = new uint256[](lenA + lenB);

        for (i = 0; i < lenA; i++) arrC[i] = arrA[i];
        for (i = 0; i < lenB; i++) arrC[lenA + i] = arrB[i];

        return arrC;
    }

    function minus(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (uint256[] memory)
    {
        uint256 lenA = arrA.length;
        uint256 lenB = arrB.length;

        uint256[] memory arrC = new uint256[](lenA);

        uint256 pointer;

        while (lenA > 0) {
            bool flag = false;
            lenB = arrB.length;
            
            while (lenB > 0) {
                if (arrB[lenB - 1] == arrA[lenA - 1]) {
                    flag = true;
                    break;
                }
                lenB--;
            }

            if (!flag) {
                arrC[pointer] = arrA[lenA - 1];
                pointer++;
            }

            lenA--;
        }

        return resize(arrC, pointer);
    }

    function fullyCoveredBy(uint256[] memory arrA, uint256[] memory arrB)
        public pure returns (bool)
    {
        uint256[] memory arrAr = refine(arrA);
        uint256[] memory arrBr = refine(arrB);

        uint256 lenA = arrAr.length;
        uint256 lenB = arrBr.length;

        while (lenA > 0) {
            uint256 i;
            while (i < lenB) {
                if (arrBr[i] == arrAr[lenA-1]) break;
                i++;
            }
            if (i==lenB) return false;
            lenA--;
        }

        return true;
    }
}
