// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";
// import "./Strings.sol";
import "./Base64.sol";
import "./strings.sol";



library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }


    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}



contract NotDittoComing is ERC721A, Ownable {
    mapping(uint256 => string) private _transformations;

    mapping(address => uint256) private _minters;

    bytes4 private ERC721InterfaceId = 0x80ac58cd;
    bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public  NUM_FREE_MINTS = 1000;
    uint256 public  MAX_FREE_PER_WALLET = 1;
    bool public isPublicSaleActive = false;
    uint256 public  PUBLIC_SALE_PRICE = 0.001 ether;

    string baseTokenURI = "ipfs://QmQJGn3Y9cUzxp6oNJ2XNaWmFdU24Mbi6rsmBWq4nrCCcu/";

    mapping(address => bool) private CONTRACTS_TRANSFORM;

    constructor() ERC721A("Not Ditto Coming", "NDC") {}

    function isLegalContract(address usingContractNFT) private view returns (bool) {
        return CONTRACTS_TRANSFORM[usingContractNFT];
    }

    function addContract(address[] memory contracts) public onlyOwner{

        for(uint256 i=0;i<contracts.length;i++) {
            CONTRACTS_TRANSFORM[contracts[i]]=true;
        }

    }

    function removeContract(address[] memory contracts) public onlyOwner{

        for(uint256 i=0;i<contracts.length;i++) {
            CONTRACTS_TRANSFORM[contracts[i]]=false;
        }

    }

    function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }

    function mint(uint256 numberOfTokens) external
      payable {
        require(isPublicSaleActive, "Public sale is not open");
    require(totalSupply() + numberOfTokens < MAX_SUPPLY + 1, "No more");

    if(totalSupply() > NUM_FREE_MINTS){
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
    } else {
        if (balanceOf(msg.sender) + numberOfTokens > MAX_FREE_PER_WALLET) {
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value || msg.sender == owner(),
            "Incorrect ETH value sent"
        );
        } else {
            require(
                numberOfTokens <= MAX_FREE_PER_WALLET,
                "Max mints per transaction exceeded"
            );
        }
    }
    _safeMint(msg.sender, numberOfTokens);
    }

    function ownerMint(uint256 quantity) public onlyOwner {
       require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= MAX_SUPPLY,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, quantity);
    }

    function transform(
        uint256 dittoId,
        address usingContractNFT,
        uint256 usingTokenId
    ) public {
        require(
            _exists(dittoId),
            "ERC721Metadata: dittoId for nonexistent token"
        );

        require(
            ownerOf(dittoId) == msg.sender,
            "You are not the owner of this Ditto"
        );

        require(
            CONTRACTS_TRANSFORM[usingContractNFT],
            "The contract hasn't been permitted, please contact the owner."
        );

        if (
            ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)
        ) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("tokenURI(uint256)", usingTokenId)
            );

            require(success, "Error getting tokenURI data");
            string memory uri = abi.decode(bytesUri, (string));

            _transformations[dittoId] = uri;
        } else if (
            ERC165Checker.supportsInterface(
                usingContractNFT,
                ERC1155MetadataInterfaceId
            )
        ) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("uri(uint256)", usingTokenId)
            );

            require(success, "Error getting URI data");
            string memory uri = abi.decode(bytesUri, (string));

            _transformations[dittoId] = uri;
        } 
    }

    function withdrawFromContract() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (bytes(_transformations[tokenId]).length != 0) {
            return _transformations[tokenId];
        }

        return string(abi.encodePacked(baseTokenURI, "/", Strings.toString(tokenId), ".json"));
    }
    function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }

  function setFreeEach(uint256 _limit)
      external
      onlyOwner
  {
      MAX_FREE_PER_WALLET = _limit;
  }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
  {
      isPublicSaleActive = _isPublicSaleActive;
  }

}