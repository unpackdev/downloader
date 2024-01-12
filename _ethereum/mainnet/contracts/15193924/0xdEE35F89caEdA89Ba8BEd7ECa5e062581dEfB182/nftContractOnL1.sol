//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./IERC721.sol";

contract Eighty80_l1 is ERC721Enumerable, Ownable, Pausable, ILayerZeroReceiver {

    using Strings for uint;

    string public _tokenBaseURI;
    uint public currentIndex;
    uint public maxSupply;
    uint public individualCap;
    ILayerZeroEndpoint public migrationHandler;
    mapping (address => uint) public numberOfTokenMinted;

    constructor (address _migrator) ERC721('Eighty80TestNFT','8080') {
        migrationHandler = ILayerZeroEndpoint(_migrator);
        maxSupply = 560;
        individualCap = 2;
    }

    function changeMigrationHandler(address _handler) external onlyOwner {
        migrationHandler = ILayerZeroEndpoint(_handler);
    }


    function mint(address _to, uint amount) public payable {
        require (maxSupply >= currentIndex + amount, "Error: Max Supply Reached");
        require (individualCap  >= numberOfTokenMinted[msg.sender]+amount,"Error: Cap Reached");
        numberOfTokenMinted[msg.sender] += amount;
        for (uint i=0;i<amount;i++) {
            currentIndex+=1;
            _mint(_to,currentIndex);
        }
    }


    function mintTokens(address _to, uint[] memory tokenIds) internal {
        for (uint i=0; i< tokenIds.length; i++) {
            require (maxSupply >= tokenIds[i], 'Error: Invalid TokenId');
            _mint(_to, tokenIds[i]);
        }
    }

    function burnTokens (uint[] memory tokenIds) public {
        for (uint i=0; i< tokenIds.length; i++) {
            require (maxSupply >= tokenIds[i], 'Error: Invalid TokenId');
            require (ownerOf(tokenIds[i]) == msg.sender, '!Owner');
            _burn(tokenIds[i]);
        }
    }

    function transferTokensToL2(uint[] memory tokenIds, bytes memory l2Contract, uint gas, uint16 destinationChainId) external payable{
        burnTokens(tokenIds);
        bytes memory payload = abi.encode(msg.sender,tokenIds);
        uint16 version = 1;
        bytes memory adaptorParams = abi.encodePacked(version, gas);
        (uint messageFees, ) = migrationHandler.estimateFees(destinationChainId,address(this),payload,false,adaptorParams);
        require(msg.value > messageFees, 'Insufficient Amount Sent');
        migrationHandler.send{value:msg.value}(
            destinationChainId,
            l2Contract,
            payload,
            payable(msg.sender),
            address(0x0),
            adaptorParams
        );
    }

    function lzReceive(
        uint16,
        bytes memory ,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(migrationHandler));
        (address toAddress, uint256[] memory tokenIds) = abi.decode(
            _payload,
            (address, uint256[])
        );
        mintTokens(toAddress, tokenIds);
    }


    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        address userAddress,
        uint[] memory tokenIds
    ) public view returns (uint256 nativeFee, uint256 zroFee) {
        return
        migrationHandler.estimateFees(
            10009,
            address(this),
            abi.encode(userAddress, tokenIds),
            false,
            abi.encodePacked(uint16(1),uint256(350000))
        );
    }


    function changeCap(uint _cap) external onlyOwner {
        individualCap = _cap;
    }

    function change_max_supply(uint supply) external onlyOwner {
        maxSupply = supply;
    }

    function withdrawEther () external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner  {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

}
