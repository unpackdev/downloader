// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./Ownable.sol";

contract Nftattributes is Ownable{
    
    //struct to track which canonical attributes are created for the whole collection. It could happen that an attribute is removed from Canonicals, but it still lives in an NFT.
    struct attCanonicals{
        mapping(string => bool) isCanonical;
        string[] canonicals;
    }
    
    attCanonicals private attCanonical;
    
    //struct which is used to store the attributes for each NFT
    struct data{
        mapping(string => string) attData;
        bool isAtt;
    }
    
    mapping(address => data) private attributes;
    
    //sets an attribute to an NFT, if attribute is not canonical it adds it, if NFT has not a single attribute, it creates the data struct to store attributes.
    function setAttribute(address _a, string memory _att_name, string memory _att_value) public onlyOwner{
        // if attribute is completely new, then I add it to the canonicals to keep track of which attributes we've created.
        if(!isAttCanonical(_att_name)){
            attCanonical.isCanonical[_att_name]=true;
            attCanonical.canonicals.push(_att_name);
        }
        if(!isAtt(_a)){
            data storage attData = attributes[_a];
            attData.isAtt = true;
            attData.attData[_att_name]=_att_value;

        }else{
            data storage attData = attributes[_a];
            attData.attData[_att_name]=_att_value;
            }
        
    }
    //returns the value of an attribue. You can get the list of possible attributes from getAllCanonicalAttributes function
    function getAttribute(address _a, string memory _att_name) public view returns(string memory) {
        return attributes[_a].attData[_att_name];
    }
    //check if it NFT address has any attribute
    function isAtt(address _a) internal view returns(bool isIndeed) {
        return attributes[_a].isAtt;
    }
    //checks is attributes is already in the canonical list.
    function isAttCanonical(string memory _canonical) internal view returns(bool isIndeed){
        return attCanonical.isCanonical[_canonical];
        
    }
    //returns a list of Canonical attributes available
    function getAllCanonicalAttributes() public view returns(string[] memory){
        uint256 len = attCanonical.canonicals.length;
        string[] memory  allCanonicalAttributes = new string[](len);
        for(uint256 i=0; i<= len-1; i++){
            if(isAttCanonical(attCanonical.canonicals[i])){
            allCanonicalAttributes[i] =attCanonical.canonicals[i];
            }
        }
        return allCanonicalAttributes;

    }
    
    //returns a list of Canonical attributes available
    function getAllAttributes(address _a) public view returns(string[] memory){
        uint256 len = attCanonical.canonicals.length;
        string[] memory  allAttributes = new string[](len);
        string memory att;
        for(uint256 i=0; i<= len-1; i++){
            att = attCanonical.canonicals[i];
            if(isAttCanonical(attCanonical.canonicals[i])){
            allAttributes[i] = attributes[_a].attData[att];
            }
        }
        return allAttributes;
    }
    //set all attributes from an address NFT to nothing.
    function resetAttributes(address _a) public onlyOwner {
        uint256 len = attCanonical.canonicals.length;
        for(uint256 i=0;i<=len-1;i++){
            delete attributes[_a].attData[attCanonical.canonicals[i]];
        }
        data storage attData = attributes[_a];
        attData.isAtt = false;
        
    }
    //removes a canonical from the list, useful when mistake.
    function removeCanonical(string memory _att_name) public onlyOwner{
        require(isAttCanonical(_att_name),"That attribute is not canonical, nothing to remove");
        attCanonical.isCanonical[_att_name]=false;
        uint256 index;
        //find the index where the att_name is at

        for(uint256 i=0; i<=attCanonical.canonicals.length-1; i++){
            if(keccak256(abi.encodePacked(attCanonical.canonicals[i])) == keccak256(abi.encodePacked(_att_name))){
                index = i;
                return;
            }
        }
        //move all the elements after that att_name so we remove the att_name from array.
        for(uint256 i=index; i<=attCanonical.canonicals.length-1; i++){
            attCanonical.canonicals[i] =  attCanonical.canonicals[i + 1];
        }
        //delete the last element in the array cuz now it is repeated
        delete attCanonical.canonicals[attCanonical.canonicals.length-1];
        
    }

}