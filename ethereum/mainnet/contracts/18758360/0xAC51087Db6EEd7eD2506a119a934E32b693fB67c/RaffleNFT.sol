// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ECDSA.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ONFT721A.sol";

contract RaffleNFT is Context, Ownable, ONFT721A {
    using ECDSA for bytes32;

    string private baseTokenURI = "https://api.wagmicatgirl.com/raffle/token/";

    uint256 public mintLimit = 10_000;

    uint256 public pricePerOne = 0.045 * 10 ** 18;

    address public feeAddress;
    address public signer;

    mapping(address => uint256) public mintedAmount;

    struct BuyInfo {
        address buyer;
        uint256 amount;
    }

    event BuyEvent(address buyer, uint256 amount);

    BuyInfo[] public buyList;

    uint256 public maxMint = 6;

    constructor() ONFT721A("HOOD Raffle NFT", "RAFFLE", 100000, address(0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675)) {
        feeAddress = address(0x5b0AD73070FbB382D62095Eee04f0E7604199426);
        signer = _msgSender();
    }


    function buy(uint256 quantity, bytes calldata signature) external payable {
        // make sure that signature is valid
        require(_checkValidity(_msgSender(), signature, "raffle-allow"));

        // make sure that user pays enough
        require(msg.value >= pricePerOne * quantity);

        //make sure that mint limit will not be exceeded after this mint
        require(totalSupply() + quantity <= mintLimit);

        // make sure that quantity is more than 0
        require(quantity > 0);

        // make sure that user does not mint more than maxMint
        require(mintedAmount[_msgSender()] + quantity <= maxMint);

        // send fees to fee address
        payable(feeAddress).transfer(msg.value);

        //mint nft to msgSender
        _mint(_msgSender(), quantity);

        // increase minted amount
        mintedAmount[_msgSender()] += quantity;

        // add entry to buy list
        buyList.push(BuyInfo(_msgSender(), quantity));

        // emit buy event
        emit BuyEvent(_msgSender(), quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseUri(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getBuyList() external view returns (BuyInfo[] memory) {
        return buyList;
    }

    function getBuyListLength() external view returns (uint256) {
        return buyList.length;
    }

    function _checkValidity(address _requester, bytes calldata _signature, string memory _action)
    private
    view
    returns (bool)
    {
        bytes32 hashVal = keccak256(abi.encodePacked(_requester, _action));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();

        return signedHash.recover(_signature) == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
