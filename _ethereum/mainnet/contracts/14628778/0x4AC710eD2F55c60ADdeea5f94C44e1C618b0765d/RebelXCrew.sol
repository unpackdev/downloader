// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";

import "./ERC721A.sol";

contract RebelXCrew is Context, ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public _isRevealed = false;
    bool public _isPreSaleActive = false;
    bool public _isPublicSaleActive = false;

    uint256 public PRICE = 0.15 ether;
    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_BY_MINT = 10;
    uint256 public MAX_PER_ADDRESS = 20;
    uint256 private NEXT_AIRDROP_ID = 0;

    string private _baseTokenURI;
    string private _preRevealURI;

    mapping(address => bool) private _whiteList;

    struct wallet {
        address walletAddress;
        uint256 amount;
        bool airdropt;
    }

    wallet[] private privSale11Wallets;
    wallet[] private privSale12Wallets;
    wallet[] private privSale21Wallets;
    wallet[] private privSale22Wallets;

    event TokenMinted(uint256 supply);

    constructor(string memory _uri) ERC721A("RebelXCrew", "$RXC") {
        setPreRevealURI(_uri);
    }

    function onWhiteList(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function mint_sale(uint256 qty) public payable {
        require(
            _isPreSaleActive || _isPublicSaleActive,
            "Sale isn't started yet"
        );
        require(qty > 0, "At least one should be minted");
        require(qty <= MAX_BY_MINT, "Exceeds mint quantity per transaction");
        require(totalSupply() + qty < MAX_SUPPLY, "Exceeding max supply");
        require(PRICE * qty <= msg.value, "Not enough ether sent");
        if (_isPreSaleActive) {
            require(_whiteList[msg.sender], "You are not in the WhiteList");
            require(
                balanceOf(msg.sender) + qty <= MAX_PER_ADDRESS,
                "Exceeds balance"
            );
        }

        _safeMint(msg.sender, qty);
        emit TokenMinted(totalSupply());
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_isRevealed == false) {
            return
                bytes(_preRevealURI).length > 0
                    ? string(
                        abi.encodePacked(
                            _preRevealURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, Strings.toString(tokenId))
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function burnBatch(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenOwnership memory owner = ownershipOf(tokenIds[i]);
            bool isApprovedOrOwner = (msg.sender == owner.addr ||
                getApproved(tokenIds[i]) == msg.sender ||
                isApprovedForAll(owner.addr, msg.sender));
            if (isApprovedOrOwner) {
                _burn(tokenIds[i]);
            }
        }
    }

    function getTokenExist(uint256 tokenId) external view returns (bool) {
        if (_exists(tokenId)) return true;
        else return false;
    }

    function addWalletsInfo(
        uint256 _type,
        address[] calldata _addresses,
        uint256[] calldata amount
    ) public onlyOwner {
        if (_type == 11) {
            for (uint256 i = 0; i < _addresses.length; i++) {
                bool _isAdded = false;
                for (uint256 j = 0; j < privSale11Wallets.length; j++) {
                    if (privSale11Wallets[j].walletAddress == _addresses[i]) {
                        _isAdded = true;
                    }
                }
                if (_isAdded == false) {
                    privSale11Wallets.push(
                        wallet({
                            walletAddress: _addresses[i],
                            amount: amount[i],
                            airdropt: true
                        })
                    );
                }
            }
        } else if (_type == 12) {
            for (uint256 i = 0; i < _addresses.length; i++) {
                bool _isAdded = false;
                for (uint256 j = 0; j < privSale12Wallets.length; j++) {
                    if (privSale12Wallets[j].walletAddress == _addresses[i]) {
                        _isAdded = true;
                    }
                }
                if (_isAdded == false) {
                    privSale12Wallets.push(
                        wallet({
                            walletAddress: _addresses[i],
                            amount: amount[i],
                            airdropt: true
                        })
                    );
                }
            }
        } else if (_type == 21) {
            for (uint256 i = 0; i < _addresses.length; i++) {
                bool _isAdded = false;
                for (uint256 j = 0; j < privSale21Wallets.length; j++) {
                    if (privSale21Wallets[j].walletAddress == _addresses[i]) {
                        _isAdded = true;
                    }
                }
                if (_isAdded == false) {
                    privSale21Wallets.push(
                        wallet({
                            walletAddress: _addresses[i],
                            amount: amount[i],
                            airdropt: true
                        })
                    );
                }
            }
        } else if (_type == 22) {
            for (uint256 i = 0; i < _addresses.length; i++) {
                bool _isAdded = false;
                for (uint256 j = 0; j < privSale22Wallets.length; j++) {
                    if (privSale22Wallets[j].walletAddress == _addresses[i]) {
                        _isAdded = true;
                    }
                }
                if (_isAdded == false) {
                    privSale22Wallets.push(
                        wallet({
                            walletAddress: _addresses[i],
                            amount: amount[i],
                            airdropt: true
                        })
                    );
                }
            }
        }
    }

    function airdropWithWalletsInfo(uint256 _type) public onlyOwner {
        if (_type == 11) {
            for (uint256 i = 0; i < privSale11Wallets.length; i++) {
                if (
                    privSale11Wallets[i].airdropt == true &&
                    privSale11Wallets[i].amount > 0
                ) {
                    for (uint256 j = 0; j < privSale11Wallets[i].amount; j++) {
                        transferFrom(
                            msg.sender,
                            privSale11Wallets[i].walletAddress,
                            NEXT_AIRDROP_ID
                        );
                        NEXT_AIRDROP_ID += 1;
                    }
                    privSale11Wallets[i].airdropt = false;
                }
            }
        } else if (_type == 12) {
            for (uint256 i = 0; i < privSale12Wallets.length; i++) {
                if (
                    privSale12Wallets[i].airdropt == true &&
                    privSale12Wallets[i].amount > 0
                ) {
                    for (uint256 j = 0; j < privSale12Wallets[i].amount; j++) {
                        transferFrom(
                            msg.sender,
                            privSale12Wallets[i].walletAddress,
                            NEXT_AIRDROP_ID
                        );
                        NEXT_AIRDROP_ID += 1;
                    }
                    privSale12Wallets[i].airdropt = false;
                }
            }
        } else if (_type == 21) {
            for (uint256 i = 0; i < privSale21Wallets.length; i++) {
                if (
                    privSale21Wallets[i].airdropt == true &&
                    privSale21Wallets[i].amount > 0
                ) {
                    for (uint256 j = 0; j < privSale21Wallets[i].amount; j++) {
                        transferFrom(
                            msg.sender,
                            privSale21Wallets[i].walletAddress,
                            NEXT_AIRDROP_ID
                        );
                        NEXT_AIRDROP_ID += 1;
                    }
                    privSale21Wallets[i].airdropt = false;
                }
            }
        } else if (_type == 22) {
            for (uint256 i = 0; i < privSale22Wallets.length; i++) {
                if (
                    privSale22Wallets[i].airdropt == true &&
                    privSale22Wallets[i].amount > 0
                ) {
                    for (uint256 j = 0; j < privSale22Wallets[i].amount; j++) {
                        transferFrom(
                            msg.sender,
                            privSale22Wallets[i].walletAddress,
                            NEXT_AIRDROP_ID
                        );
                        NEXT_AIRDROP_ID += 1;
                    }
                    privSale22Wallets[i].airdropt = false;
                }
            }
        }
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _whiteList[addresses[i]] = true;
        }
    }

    function removeFromWhiteList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _whiteList[addresses[i]] = false;
        }
    }

    function enablePreSale(bool _enabled) public onlyOwner {
        _isPreSaleActive = _enabled;
    }

    function enablePublicSale(bool _enabled) public onlyOwner {
        _isPublicSaleActive = _enabled;
    }

    function airdrop(address recipient, uint256 qty) public onlyOwner {
        require(totalSupply() + qty < MAX_SUPPLY, "Exceeding max supply");

        _safeMint(recipient, qty);
        emit TokenMinted(totalSupply());
    }

    function setReveal() public onlyOwner {
        _isRevealed = true;
    }

    function setConfigs(uint256 _price, uint256 _maxByMint, uint256 _maxPerAddress) public onlyOwner {
        PRICE = _price;
        MAX_BY_MINT = _maxByMint;
        MAX_PER_ADDRESS = _maxPerAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreRevealURI(string memory preRevealURI) public onlyOwner {
        _preRevealURI = preRevealURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero.");
        _withdraw(msg.sender, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
