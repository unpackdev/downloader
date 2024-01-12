// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// https://github.com/ProjectOpenSea/opensea-creatures
//  import "./ERC721Tradable.sol";
import "./ERC721Tradable.sol";

contract OkaydogNft is ERC721Tradable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    uint256 public constant price = 0.003 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT_PER_WALLET = 5;
    string public constant baseUri = "ipfs://bafybeigqxm7ag2wgiklzhrprvbasug2nldmjvd2mlk2yddizkbvb2vjgca/";

    address public admin;

    uint256 public constant state_mint_admin = 0;
    uint256 public constant state_mint_all = 1;
    uint256 public constant state_mint_stop = 2;
    uint256 public state_mint;

    // OpenSea proxy registry addresses for rinkeby and mainnet.
    // rinkeby 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    // mainnet 0xa5409ec958C83C3f309868babACA7c86DCB077c1
    constructor(address _proxyRegistryAddress) ERC721Tradable("Okay Dog", "Okay Dog", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure virtual override returns (string memory)
    {
        return baseUri;
    }

    function totalSupplyReal() public view returns (uint256) 
    {
        return _nextTokenId.current();
    }

    function withdrawTo(address payable to) external onlyOwner
    {
        to.transfer(address(this).balance);
    }

    function setAdmin(address _admin) external onlyOwner
    {
        require(_admin != address(0), "addr arg error");

        admin = _admin;
    }

    function switchState() external onlyOwner
    {
        require(state_mint != state_mint_stop, "state change limit");

//        if (state_mint == state_mint_admin)
//        {
//            state_mint = state_mint_all;
//        }
//        else
        {
            state_mint = state_mint_stop;
        }
    }

    modifier notStop()
    {
        require(state_mint != state_mint_stop, "mint stop");
        _;
    }

    function mint(uint256 _quantity) external payable  notStop
    {
        mint_check(_quantity);

        address sender = msgSender();
        for (uint256 i = 0; i < _quantity; i++) 
        {
            _nextTokenId.increment();
            uint256 currentTokenId = _nextTokenId.current();
            _safeMint(sender, currentTokenId);
        }
    }

    function mint_check(uint256 _quantity) internal returns (bool) 
    {
        require(_quantity != 0, "arg error");

        address sender = msgSender();

        require(sender != address(0), "sender adress error");
        require(totalSupplyReal() + _quantity <= MAX_SUPPLY, "total error");

        if (sender == admin) 
        {
            return true;
        }

        uint256 already_count = balanceOf(sender);
        require(already_count + _quantity <= MAX_MINT_PER_WALLET, "user count error");

        uint256 pay_count = _quantity;
        if (already_count == 0)
        {
            pay_count -= 1;
        }
        require(msg.value >= price * pay_count, "ether value error");

        return true;
    }
}
