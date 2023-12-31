pragma solidity 0.8.7;

interface WnsResolverInterface {
    function getTxtRecords(uint256 tokenId, string memory label) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsTxtRecords {
 
    WnsResolverInterface wnsOldResolver = WnsResolverInterface(0xf56D46948ab9F850F0CdAd3D394C2751214f555F);
    WnsResolverInterface wnsNewResolver = WnsResolverInterface(0x5A1E189Fb5ba96405118FDE1F9F66464Ba9565Bf);


    function getTxtRecords(uint256 tokenId, string[] memory label) public view returns (string[] memory) {
        string[] memory result = new string[](label.length);

        for(uint256 i = 0; i < label.length; i++) {
            if(checkEqual(label[i], "avatar")) {
                string memory newResult = wnsNewResolver.getTxtRecords(tokenId, "avatar");
                if(checkEqual(newResult, "") == false) {
                    result[i] = newResult;
                } else {
                    string memory oldResult = wnsOldResolver.getTxtRecords(tokenId, "avatar");
                    result[i] = oldResult;
                }
            } else {
                result[i] = wnsNewResolver.getTxtRecords(tokenId, label[i]);
            }
        }
        return result;
    }

    function checkEqual(string memory str1, string memory str2) public pure returns(bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}