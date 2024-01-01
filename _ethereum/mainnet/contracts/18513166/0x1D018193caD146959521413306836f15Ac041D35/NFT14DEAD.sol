pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721A.sol";
import "IERC721.sol";

contract NFT14DEAD is Ownable, ERC721A {
    mapping(address => uint16) public _minted;

    bool public active;

    string public baseURI;

    uint256 total_supply = 1000;

    IERC721 springfieldPunks =
        IERC721(0x814c3Ab3c08b6E10845706680D03e7306dD21491);

    uint256 public immutable public_price = 0.005 ether;
    uint256 public immutable holder_price = 0.002 ether;

    uint256 public immutable public_free_amt = 1;
    uint256 public immutable holder_free_amt = 3;

    constructor(string memory _baseURI) ERC721A("NFT14DEAD", "NFT14DEAD") {
        baseURI = _baseURI;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        baseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function turnActive() public onlyOwner {
        active = !active;
    }

    function mint(uint16 num) external payable {
        require(active, "not in active time");
        require(
            num <= 50 && totalSupply() + num <= total_supply,
            "num exceed max mint number or out of supply"
        );

        uint256 balance = springfieldPunks.balanceOf(msg.sender);
        if (balance > 0) {
            holderMint(num);
        } else {
            publicMint(num);
        }
    }

    function publicMint(uint16 num) internal {
        uint256 ether_amount = num * public_price;
        uint256 minted_num = _minted[msg.sender];

        if (minted_num < public_free_amt) {
            if (num <= public_free_amt - minted_num) {
                ether_amount = 0;
            } else {
                ether_amount =
                    (num - (public_free_amt - minted_num)) *
                    public_price;
            }
        }

        require(msg.value >= ether_amount, "insufficient value");

        _minted[msg.sender] += num;
        _safeMint(msg.sender, num);
    }

    function holderMint(uint16 num) internal {
        uint256 ether_amount = num * holder_price;
        uint256 minted_num = _minted[msg.sender];

        if (minted_num < holder_free_amt) {
            if (num <= holder_free_amt - minted_num) {
                ether_amount = 0;
            } else {
                ether_amount =
                    (num - (holder_free_amt - minted_num)) *
                    holder_price;
            }
        }

        require(msg.value >= ether_amount, "insufficient value");

        _minted[msg.sender] += num;
        _safeMint(msg.sender, num);
    }

    receive() external payable {}

    function withdraw(uint _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
