//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

abstract contract FundsContract {
    function depositFunds(address _recipent, uint256 _lockupInSeconds)
        public
        payable
    {}
}

contract FoxyMistressGentelmenClub is
    ERC721A,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;
    event PriceChange(uint256 presalePrice, uint256 publicSalePrice);
    event SaleStateChange(uint256 newState);

    FundsContract fundsContract;

    address emergencyWallet =
        address(0xAB5a642989E44987F7d49998fE4ea0C461556bB2);

    mapping(address => uint256) public addressToWithdrawalPercentage;
    address[] public withdrawalAddresses;

    bytes32 public giftMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    uint256 public constant maxTokens = 10000;
    uint256 public maxMintPerWallet = 2;
    // Add 1 to the desired amount, because value of this gets deducted by 1 in constructor.
    uint256 public reservedTokens = 21;
    uint256 public presalePrice;
    uint256 public price;

    string private constant notRevealedJson =
        "ipfs://bafkreig3doyiveup2imeiqoek3xyscgruslck746vl72xtppvx5dijltjq";

    string public FMGC_PROVENANCE =
        "5b27bf635bda55706397863c1f720ff44eef2b9ed9f534c02048cafd3fdd5ea9";

    struct MintedPerWallet {
        uint256 presale;
        uint256 publicSale;
    }
    uint256 public ongoingGiftId;
    mapping(uint256 => mapping(address => bool)) public giftIdToAddressClaimed;

    enum SaleState {
        NOT_ACTIVE,
        PRESALE,
        PUBLIC_SALE
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    bool public revealed = false;

    bool public giftClaimingActive = false;
    bool private firstWithdrawal = true;

    mapping(address => MintedPerWallet) public mintedPerWallet;

    string private baseURI;

    /// @dev First 1/1 NFT named "Amelia" is minted straight in the constructor to the deployer.
    constructor(address _fundsContract)
        ERC721A("Foxy Mistress Gentleman's Club", "FMGC")
    {
        safeMint(msg.sender, 1);
        fundsContract = FundsContract(_fundsContract);
    }

    function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 root,
        uint256 _amount,
        uint256 _deadline
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        _amount.toString(),
                        _deadline.toString()
                    )
                )
            );
    }

    modifier whenEnoughTokensLeft(uint256 _amount) {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        _;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function deductFromReserve(uint256 _amount) internal {
        if (reservedTokens >= _amount) {
            reservedTokens = reservedTokens - _amount;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function claimNft(
        uint256 _amount,
        uint256 _deadline,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused whenEnoughTokensLeft(_amount) nonReentrant {
        require(giftClaimingActive, "Gift claiming is not active!");
        require(
            isValidMerkleProof(
                _merkleProof,
                giftMerkleRoot,
                _amount,
                _deadline
            ),
            "Not on list!"
        );
        require(
            !giftIdToAddressClaimed[ongoingGiftId][msg.sender],
            "Already claimed!"
        );
        require(block.timestamp <= _deadline, "Expired!");
        deductFromReserve(_amount);
        giftIdToAddressClaimed[ongoingGiftId][msg.sender] = true;
        _safeMint(msg.sender, _amount);
    }

    function mintWhitelistNft(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(saleState == SaleState.PRESALE, "Presale not active!");
        require(
            isValidMerkleProof(_merkleProof, whitelistMerkleRoot),
            "Not on whitelist!"
        );
        require(
            msg.value >= presalePrice * _amount,
            string(abi.encodePacked("Not enough ETH!"))
        );
        require(
            _amount + mintedPerWallet[msg.sender].presale <= maxMintPerWallet,
            string(abi.encodePacked("Too many tokens per wallet!"))
        );
        require(
            maxTokens - reservedTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        safeMint(msg.sender, _amount);
    }

    function mintNft(uint256 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            msg.value >= price * _amount,
            string(abi.encodePacked("Not enough ETH!"))
        );
        require(saleState == SaleState.PUBLIC_SALE, "Public sale not active!");
        require(
            _amount + mintedPerWallet[msg.sender].publicSale <=
                maxMintPerWallet,
            string(abi.encodePacked("Too many tokens per wallet!"))
        );
        require(
            maxTokens - reservedTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        safeMint(msg.sender, _amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return notRevealedJson;
    }

    function getPrice() public view returns (uint256) {
        if (saleState == SaleState.PRESALE) {
            return presalePrice;
        } else if (saleState == SaleState.PUBLIC_SALE) {
            return price;
        }
        return 0;
    }

    function safeMint(address _to, uint256 _amount)
        internal
        whenEnoughTokensLeft(_amount)
    {
        if (msg.sender == owner()) {
            deductFromReserve(_amount);
        } else {
            if (saleState == SaleState.PUBLIC_SALE) {
                mintedPerWallet[msg.sender].publicSale += _amount;
            } else if (saleState == SaleState.PRESALE) {
                mintedPerWallet[msg.sender].presale += _amount;
            }
        }
        _safeMint(_to, _amount);
    }

    // Only owner functions
    function setFundsContractAddress(address _address) external onlyOwner {
        fundsContract = FundsContract(_address);
    }

    function setWithdrawalDistrubution(
        address[] memory _wallets,
        uint256[] memory _percentages
    ) public onlyOwner {
        require(
            _wallets.length == _percentages.length,
            "Wallets and pecentages counts don't match!"
        );

        uint256 totalPercentage;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentage += _percentages[i];
        }
        require(
            totalPercentage == 90,
            "Percentages provided combined value is not 90"
        );
        address[] memory tempWithdrawalAddresses = new address[](_wallets.length);
        for (uint256 i = 0; i < _wallets.length; i++) {
            tempWithdrawalAddresses[i] = _wallets[i];
            addressToWithdrawalPercentage[_wallets[i]] = _percentages[i];
        }
        withdrawalAddresses = tempWithdrawalAddresses;
    }

    function withdrawBalance() external onlyOwner {
        require(
            withdrawalAddresses.length > 0,
            "Withdrawal addresses not set!"
        );

        uint256 totalBalance = address(this).balance;
        if (!firstWithdrawal) {
            fundsContract.depositFunds{value: totalBalance / 10}(
                payable(emergencyWallet),
                31536000 // 1 year
            );
        } else {
            firstWithdrawal = false;
            (bool success, ) = payable(emergencyWallet).call{
                value: totalBalance / 10
            }("");
            require(success, "Withdrawal failed!");
        }

        for (uint256 i = 0; i < withdrawalAddresses.length; i++) {
            uint256 withdrawalPercentage = addressToWithdrawalPercentage[
                withdrawalAddresses[i]
            ];
            (bool success, ) = payable(withdrawalAddresses[i]).call{
                value: (totalBalance / 100) * withdrawalPercentage
            }("");
            require(success, "Withdrawal failed!");
        }
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        emit PriceChange(_price, price);
        presalePrice = _price;
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        emit PriceChange(presalePrice, _price);
        price = _price;
    }

    function toggleGiftClaiming() external onlyOwner {
        giftClaimingActive = !giftClaimingActive;
    }

    function stopSale() external onlyOwner {
        emit SaleStateChange(0);
        saleState = SaleState.NOT_ACTIVE;
    }

    function startPresale() external onlyOwner {
        emit SaleStateChange(1);
        require(presalePrice > 0, "Presale price is not set!");
        saleState = SaleState.PRESALE;
    }

    function startPublicSale() external onlyOwner {
        emit SaleStateChange(2);
        require(price > 0, "Public sale price is not set!");
        saleState = SaleState.PUBLIC_SALE;
    }

    function setBaseUri(string memory _ipfsCID) public onlyOwner {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
    }

    function revealTokens(string memory _ipfsCID) external onlyOwner {
        require(!revealed, "Already revealed!");
        setBaseUri(_ipfsCID);
        revealed = true;
    }

    function setMaxMintPerWallet(uint256 _amount) external onlyOwner {
        maxMintPerWallet = _amount;
    }

    function setReservedTokens(uint256 _amount) external onlyOwner {
        require(
            maxTokens >= totalSupply() + _amount,
            "Not enough tokens left to reserve!"
        );
        reservedTokens = _amount;
    }

    function setGiftMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        giftMerkleRoot = _merkleRoot;
        ongoingGiftId++;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function airdropNft(uint256 _amount, address _to) external onlyOwner {
        safeMint(_to, _amount);
    }

    function setEmergencyWalletAddress(address _address) external onlyOwner {
        require(_address != address(0), "Zero address!");
        emergencyWallet = _address;
    }
    function setProvenance(string calldata _provenance) external onlyOwner {
        FMGC_PROVENANCE = _provenance;
    }
    receive() external payable {}
}
