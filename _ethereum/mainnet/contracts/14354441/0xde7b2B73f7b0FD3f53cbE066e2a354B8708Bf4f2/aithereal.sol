// SPDX-License-Identifier: MIT
/*
    |      ||    .   '||                                      '||  
   |||    ...  .||.   || ..     ....  ... ..    ....   ....    ||  
  |  ||    ||   ||    ||' ||  .|...||  ||' '' .|...|| '' .||   ||  
 .''''|.   ||   ||    ||  ||  ||       ||     ||      .|' ||   ||  
.|.  .||. .||.  '|.' .||. ||.  '|...' .||.     '|...' '|..'|' .||. 
*/
pragma solidity 0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract aithereal is ERC721Enumerable, Ownable {
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenCount;

    string public baseURI;

    uint256 public price = 50000000000000000;
    uint256 public maxTokens = 1111;
    uint256 public maxPerWallet = 1;
    address constant addressOne = 0x1Dac794d333ce41461540a0BCF8195029EFE6557; // dev
    address constant addressTwo = 0x510A1415b7CB464A46793E910c8FbAd715B72394; // axl
    address constant addressThree = 0x057c9e2346b1dB62191CDb838DB1C32d28397f57; // papageo
    address constant addressFour = 0x370433a205B84839B507420B8E22900BAb902a8b; // infastructure

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    mapping(address => uint256) public minted;
    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    constructor(string memory baseURl) ERC721("Aithereals", "AITH") {
        setBaseURI(baseURl);
    }

    modifier onlyAuthorised() {
        require(
            (_msgSender() == addressOne) ||
                (_msgSender() == addressTwo) ||
                (_msgSender() == addressThree) ||
                (owner() == _msgSender()),
            "Caller is not authorised"
        );
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    /* Set a value */
    function setBaseURI(string memory __baseURI) public onlyAuthorised {
        baseURI = __baseURI;
    }

    function setMaxPerWallet(uint256 _amount) public onlyAuthorised {
        maxPerWallet = _amount;
    }

    function flipSaleState() public onlyAuthorised {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyAuthorised {
        presaleIsActive = !presaleIsActive;
    }

    function setMintPrice(uint256 newPrice) public onlyAuthorised {
        price = newPrice;
    }

    function setMaxTokens(uint256 tokens) public onlyAuthorised {
        maxTokens = tokens;
    }

    function mint(uint256 _amount) external payable {
        require(saleIsActive, "Sale must be active");
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        require(
            minted[msg.sender] + _amount <= maxPerWallet,
            "Purchase would exceed max tokens per wallet"
        );
        require(
            _tokenCount.current() + _amount <= maxTokens,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= price * _amount,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < _amount; i++) {
            _tokenCount.increment();
            _safeMint(msg.sender, _tokenCount.current());
        }

        minted[msg.sender] += _amount;
    }

    function mintPreSale(uint256 _amount) external payable {
        require(
            !Address.isContract(msg.sender),
            "Contracts are not allowed to mint"
        );
        require(presaleIsActive, "Pre Sale is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(
            _allowListClaimed[msg.sender] + _amount <= maxPerWallet,
            "Purchase exceeds max allowed"
        );
        require(
            minted[msg.sender] + _amount <= maxPerWallet,
            "Purchase would exceed max tokens per wallet"
        );
        require(
            _tokenCount.current() + _amount <= maxTokens,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= price * _amount,
            "Ether value sent is not correct"
        );

        for (uint256 i; i < _amount; i++) {
            _tokenCount.increment();
            _allowListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, _tokenCount.current());
        }
    }

    function addToAllowList(address[] calldata addresses)
        external
        onlyAuthorised
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;
            _allowListClaimed[addresses[i]] > 0
                ? _allowListClaimed[addresses[i]]
                : 0;
        }
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        onlyAuthorised
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function reserve(address _to, uint256 _amount) public onlyAuthorised {
        require(
            _amount > 0 && _tokenCount.current() + _amount <= maxTokens,
            "Purchase would exceed max supply of tokens"
        );
        for (uint256 i; i < _amount; i++) {
            _tokenCount.increment();
            _safeMint(_to, _tokenCount.current());
        }
    }

    /* Withdrawal */
    function withdrawAll() external onlyAuthorised {
        uint256 _balance = address(this).balance;
        payable(addressOne).transfer((_balance * 5) / 100);
        payable(addressThree).transfer((_balance * 5) / 100);
        payable(addressFour).transfer((_balance * 5) / 100);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() external onlyAuthorised {
        payable(msg.sender).transfer(address(this).balance);
    }
}
