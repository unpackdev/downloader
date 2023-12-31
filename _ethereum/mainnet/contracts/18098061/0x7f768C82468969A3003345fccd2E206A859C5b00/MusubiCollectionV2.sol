// SPDX-License-Identifier: MIT

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import "./Ownable.sol";
import "./MerkleProof.sol";


pragma solidity >=0.7.0 <0.9.0;

interface iNFTCollection {
    function balanceOf(address _owner) external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address);
    //function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// コントラクト名
contract MusubiV2_burnin is Ownable{

    string public baseURI;
    string public baseURIBurnin;
    string public baseExtension = ".json";
    mapping(uint256 => bool) public burninFlag;

    constructor(){
        setNFTCollection(0x83B265B7b89E967318334602be9ea57b1a8d3b47); //コレクションのコントラクトアドレス0x83B265B7b89E967318334602be9ea57b1a8d3b47
        setBaseURI("https://musubicollection.xyz/data/metadata/"); //burnin前のメタデータhttps://musubicollection.xyz/data/metadata/
        setBaseURIBurnin("https://musubicollection.xyz/data/v2metadata/"); //burnin後のメタデータ
        setMerkleRoot(0x70352fae0cd18cc57b9bdaa456f467c9a12d4a667bd9544165adea91f8f6f064);
    }



    //
    //withdraw section
    //

    address public withdrawAddress = 0x52C5DcF49f10C827E070cee4aDf1D006942eAaB6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }



    uint256 public cost = 10000000000000000;// 価格wei
    uint256 public maxBurnin = 400; //burnin枚数
    uint256 public totalBurnin = 0; //burnin枚数
    bool public paused = true;
    bool public onlyAllowlisted = true;
    bytes32 public merkleRoot;
    mapping(address => uint256) public userBurnedAmount;

    iNFTCollection public NFTCollection;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function burnin( uint256 _maxBurninAmount , bytes32[] calldata _merkleProof , uint256 _burnId ) public payable callerIsUser{

        require( !paused, "the contract is paused");
        require( totalBurnin + 1  <= maxBurnin , "max NFT limit exceeded");
        require( cost <= msg.value, "insufficient funds");
        require( nftOwnerOf( _burnId ) == msg.sender, "Owner is different" );
        require( burninFlag[_burnId] == false , "already burned" );


        uint256 maxMintAmountPerAddress = 0;
        if(onlyAllowlisted == true) {
            //Merkle tree
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxBurninAmount) );
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
            maxMintAmountPerAddress = _maxBurninAmount;
            require( userBurnedAmount[msg.sender] + 1 <= maxMintAmountPerAddress , "max NFT per address exceeded");
            userBurnedAmount[msg.sender] += 1;
        }

        totalBurnin += 1;
        burninFlag[_burnId] = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxBurnin(uint256 _maxBurnin) public onlyOwner {
        maxBurnin = _maxBurnin;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyAllowlisted(bool _state) public onlyOwner {
        onlyAllowlisted = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setNFTCollection(address _address) public onlyOwner {
        NFTCollection = iNFTCollection(_address);
    }

    function nftOwnerOf(uint256 _tokenId)public view returns(address){
        return NFTCollection.ownerOf(_tokenId);
    }
    function nftBalanceOf(address _address)public view returns(uint256){
        return NFTCollection.balanceOf(_address);
    }

    //function nftTokensOfOwner(address owner) public view returns (uint256[] memory){
    //    return NFTCollection.tokensOfOwner(owner);
    //}

    function nftTokensOfOwner(address _address) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = NFTCollection.balanceOf(_address);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                try NFTCollection.ownerOf(i) {
                    if (NFTCollection.ownerOf(i) == _address) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                } catch {
                    // nothing
                }
            }
            return tokenIds;   
        }
    }


    function burnedTokenIds()public view returns(uint256[] memory){
        uint256 tokenIdsIdx;
        uint256 tokenIdsLength = totalBurnin;
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        for (uint256 i = 0 ; tokenIdsIdx != tokenIdsLength; ++i) {
            if ( burninFlag[i] == true){
                tokenIds[tokenIdsIdx++] = i;                
            }
        }
        return tokenIds;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        if( burninFlag[_tokenId] == false ){
            return string(abi.encodePacked(baseURI, _toString(_tokenId), baseExtension));
        }else{
            return string(abi.encodePacked(baseURIBurnin, _toString(_tokenId), baseExtension));
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseURIBurnin(string memory _newBaseURI) public onlyOwner {
        baseURIBurnin = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }


    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

}