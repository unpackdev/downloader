// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

interface IGGold {
    function balanceOf(address owner) external view returns (uint);
    function burn(address account, uint amount) external;
}

contract GHGShips is ERC721, Ownable, Pausable, ReentrancyGuard {
    uint private constant MINT_PER_TX_LIMIT = 20;

    uint public tokensMinted = 0;
    uint public paidTokensMinted = 0;
    uint public priceInEth = 0.5 ether;
    uint public minPriceInEth = 0.07 ether;
    uint public priceInGGold = 300000 ether;
    uint public startSaleDate;

    address public shareAddress;

    mapping(address => bool) public bannedWallets;
    mapping(address => bool) public approvedManagers;
    mapping(uint16 => bool) private _isPirate;
    IGGold public gold;

    string private _apiURI = "https://gold-hunt-ships.herokuapp.com/token/";

    uint16[] private _availablePaidTokens;
    uint16[] private _availableTokens;

    constructor() ERC721("GHGShips", "GHGSHIP") {
        _pause();
        _safeMint(msg.sender, 0);
        tokensMinted += 1;

        fillPaidTokens(1, 2500);
        fillTokens(2501, 5000);
    }

    function fillTokens(uint16 _from, uint16 _to) public onlyOwner {
        for (uint16 i = _from; i <= _to; i++) {
            _availableTokens.push(i);
        }
    }
    function fillPaidTokens(uint16 _from, uint16 _to) public onlyOwner {
        for (uint16 i = _from; i <= _to; i++) {
            _availablePaidTokens.push(i);
        }
    }

    function setPirateIds(uint16[] calldata ids) external onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            _isPirate[ids[i]] = true;
        }
    }

    function isPirate(uint16 id) public view returns (bool) {
        return _isPirate[id];
    }

    function giveAway(uint _amount, address _address, bool _paid) public onlyOwner {
        if (_paid) {
            require(_availablePaidTokens.length > 0, "All tokens are minted");
        } else {
            require(_availableTokens.length > 0, "All tokens are minted");
        }

        for (uint i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted(_paid);
            _safeMint(_address, tokenId);
        }
    }

    function mint(uint _amount, bool _paid) public payable whenNotPaused nonReentrant {
        require(bannedWallets[msg.sender] == false, "Banned wallet is not allowed to mint");
        require(tx.origin == msg.sender, "Only EOA");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT,"Invalid mint amount");

        uint totalGoldCost = 0;
        if (_paid) {
            // Paid mint
            require(_availablePaidTokens.length > 0, "All tokens are minted");
            require(msg.value >= mintPrice(_amount), "Invalid payment amount");
        } else {
            // GGold burn
            require(_availableTokens.length > 0, "All tokens are minted");
            require(msg.value == 0, "Now minting is done via GGold");
            totalGoldCost = mintPriceForGold(_amount);
            require(gold.balanceOf(msg.sender) >= totalGoldCost, "Not enough GGold");
        }

        if (totalGoldCost > 0) {
            gold.burn(msg.sender, totalGoldCost);
        }

        if (_paid) {
            paidTokensMinted += _amount;
        }
        tokensMinted += _amount;
        for (uint i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted(_paid);
            _safeMint(msg.sender, tokenId);
        }
    }

    function getTokenToBeMinted(bool _paid) private returns (uint16) {
        uint limit = _paid
            ? _availablePaidTokens.length
            : _availableTokens.length;
        uint16 randomIndex = random(limit, limit);
        
        uint16 tokenId = _paid
            ? _availablePaidTokens[randomIndex]
            : _availableTokens[randomIndex];
        
        if (_paid) {
            _availablePaidTokens[randomIndex] = _availablePaidTokens[_availablePaidTokens.length - 1];
            _availablePaidTokens.pop();
        } else {
            _availableTokens[randomIndex] = _availableTokens[_availableTokens.length - 1];
            _availableTokens.pop();
        }

        return tokenId;
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function pause() external onlyOwner {
        _pause();
    }
    function startSale() external onlyOwner {
        startSaleDate = block.timestamp;
        unpause();
    }

    function mintPrice(uint _amount) public view returns (uint) {
        uint diff = block.timestamp - startSaleDate;
        if (diff > 1 days) return minPriceInEth * _amount;

        uint fraction = (diff / 10 minutes) * 0.003 ether;
        if (fraction >= priceInEth) return minPriceInEth * _amount;

        return (priceInEth - fraction) * _amount;
    }

    function mintPriceForGold(uint _amount) public view returns (uint) {
        return _amount * priceInGGold;
    }
    function setGold(address _address) external onlyOwner {
        gold = IGGold(_address);
    }
    function changeEthPrice(uint _weiPrice) external onlyOwner {
        priceInEth = _weiPrice;
    }
    function changeMinEthPrice(uint _weiPrice) external onlyOwner {
        minPriceInEth = _weiPrice;
    }
    function changePriceInGGold(uint _weiPrice) public onlyOwner {
        priceInGGold = _weiPrice;
    }

    function random(uint _seed, uint _limit) internal view returns (uint16) {
        uint randomValue = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    tokensMinted
                )
            )
        );

        return uint16(randomValue % _limit);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        // Hardcode the stacking approval so that users don't have to waste gas approving
        if (approvedManagers[msg.sender] == false)
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function banWallet(address _address, bool _banned) external onlyOwner {
        bannedWallets[_address] = _banned;
    }

    function addManager(address _address) external onlyOwner {
        approvedManagers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        approvedManagers[_address] = false;
    }

    function totalSupply() external view returns (uint) {
        return tokensMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _apiURI = uri;
    }

    function setShareAddress(address _address) external onlyOwner {
        shareAddress = _address;
    }

    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        uint share = (balance * 10) / 100;
        payable(shareAddress).transfer(share);
        payable(to).transfer(balance - share);
    }
}
