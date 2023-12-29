pragma solidity ^0.8.18;

import "./ERC721URIStorage.sol";
import "./BurntEthOSNFT.sol";
import "./Strings.sol";

contract EthOSNFT is ERC721URIStorage {
    uint256 public counter;
    BurntEthOSNFT public burntEthOSNFT;
    address public owner;
    uint256 private maxAmountOfPhone;
    uint private price = 0.39 ether;
    string private baseURL;

    event BurnedPhone(address _burner, uint256 tokenId);

    constructor() ERC721("ethOS Phone", "ETHOSPHONE") {
        counter = 0;
        owner = msg.sender;
        burntEthOSNFT = new BurntEthOSNFT(this);
        maxAmountOfPhone = 50;
        baseURL = "https://ethostokenuri-dey2ouq2ya-uc.a.run.app?p=1&t=";
    }

    function updatePrice(uint256 newPrice) public {
        require(msg.sender == owner);
        price = newPrice;
    }

    function updateMaxAmount(uint256 newAmount) public {
        require(msg.sender == owner);
        maxAmountOfPhone = newAmount;
    }

    function toUInt256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    function mintPhone(uint256 amount)
        public
        payable
        returns (uint256)
    {
        require(amount >= 1 && amount <= 3);
        require(msg.value == price * amount);

        uint256 currentCounter = counter;

        require((counter + amount) < maxAmountOfPhone);

        for (uint256 i = 0; i < amount; i++) {
            uint256 newPhoneId = currentCounter;
            _mint(msg.sender, newPhoneId);
            _setTokenURI(
                newPhoneId,
                ""
            );

            currentCounter++;
        }

        counter = currentCounter;

        return currentCounter;
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        _transfer(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            tokenId
        );
        burntEthOSNFT.mintBPhone(tokenId, msg.sender);
        emit BurnedPhone(msg.sender, tokenId);
    }

    function withdraw(address payable withdrawalAddr) public {
        require(msg.sender == owner);
        withdrawalAddr.transfer(address(this).balance);
    }


    function changeBU(string memory newBaseURL) public {
        require(msg.sender == owner);
        baseURL = newBaseURL;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string.concat(
                baseURL,
                Strings.toString(tokenId)
            );
    }
}
