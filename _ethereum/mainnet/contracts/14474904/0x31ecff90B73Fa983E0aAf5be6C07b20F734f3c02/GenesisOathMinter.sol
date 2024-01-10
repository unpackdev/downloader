// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./ERC165Checker.sol";
import "./IERC20.sol";

import "./IMintable.sol";
import "./SignedMinting.sol";

contract GenesisOathMinter is
    SignedMinting,
    AccessControlEnumerable,
    ReentrancyGuard
{
    using Address for address;

    IERC20 public paymentTokenContract;

    uint256 public constant MAX_TIER_1 = 6000;
    uint256 public constant TOKEN_ID_TIER_1 = 1;

    uint256 public constant MAX_TIER_2 = 1000;
    uint256 public constant TOKEN_ID_TIER_2 = 2;

    uint256 public constant MAX_TOTAL = MAX_TIER_1 + MAX_TIER_2;

    uint256 public constant VAULT_TIER1_PREMINT = 70;
    uint256 public constant VAULT_TIER2_PREMINT = 30;

    uint256 public constant NUM_PREMINT =
        VAULT_TIER1_PREMINT + VAULT_TIER2_PREMINT;

    uint256 public walletLimit = 10;

    uint256 public nativeSalePrice = 0.11 ether;
    uint256 public tokenSalePrice = 20 * 10**18;

    bool public saleActive;
    bool public signatureRequired;

    mapping(address => uint256) public mintsPerAddress;

    IMintable public tokenContract;

    address public vaultAddress;
    address public premintAddress;
    bool public preminted;

    constructor(
        address _mintable,
        address _paymentTokenAddress,
        address _signer,
        address _adminAddress,
        address _devAddress,
        address _vaultAddress,
        address _premintAddress
    ) SignedMinting(_signer) {
        require(
            ERC165Checker.supportsInterface(
                _mintable,
                type(IMintable).interfaceId
            ),
            "Invalid token contract"
        );
        require(_signer != address(0), "Invalid signer address");
        require(_adminAddress != address(0), "Invalid admin address");
        require(_devAddress != address(0), "Invalid dev address");
        require(_vaultAddress != address(0), "Invalid vault address");
        vaultAddress = _vaultAddress;
        premintAddress = _premintAddress;

        paymentTokenContract = IERC20(_paymentTokenAddress);
        tokenContract = IMintable(_mintable);
        _grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _devAddress);

        signatureRequired = true;
    }

    function premint() public onlyAuthorized {
        require(!preminted, "Already preminted");
        tokenContract.mint(
            premintAddress,
            TOKEN_ID_TIER_1,
            VAULT_TIER1_PREMINT
        );
        tokenContract.mint(
            premintAddress,
            TOKEN_ID_TIER_2,
            VAULT_TIER2_PREMINT
        );
        preminted = true;
    }

    function mint(
        address _to,
        uint256 _amount,
        bool tokenPayment,
        bytes memory _signature
    ) public payable {
        require(saleActive, "Sale not active");
        require(
            !signatureRequired ||
                (signatureRequired && validateSignature(_signature, _to)),
            "Requires valid signature"
        );
        require(_to != address(0), "Cannot mint to 0 address");
        require(_amount > 0, "Invalid amount");
        uint256 userMinted = mintsPerAddress[_to];
        require((userMinted + _amount) <= walletLimit, "Wallet limit");

        uint256 tier1Minted = tokenContract.totalSupply(TOKEN_ID_TIER_1);
        uint256 tier2Minted = tokenContract.totalSupply(TOKEN_ID_TIER_2);

        uint256 tier1Available = (MAX_TIER_1 - tier1Minted);
        uint256 tier2Available = (MAX_TIER_2 - tier2Minted);

        require(_amount <= (tier1Available + tier2Available), "Supply limit");

        if (tokenPayment) {
            require(
                paymentTokenContract.allowance(_msgSender(), address(this)) >=
                    (_amount * tokenSalePrice),
                "Unauthorized spend"
            );
            require(
                paymentTokenContract.balanceOf(_msgSender()) >=
                    (_amount * tokenSalePrice),
                "Not enough tokens"
            );

            paymentTokenContract.transferFrom(
                _msgSender(),
                address(this),
                _amount * tokenSalePrice
            );
        } else {
            require(
                msg.value == (nativeSalePrice * _amount),
                "Invalid payment"
            );
        }

        mintsPerAddress[_to] = userMinted + _amount;

        if (tier1Available == 0) {
            tokenContract.mint(_to, TOKEN_ID_TIER_2, _amount);
            return;
        }

        if (tier2Available == 0) {
            tokenContract.mint(_to, TOKEN_ID_TIER_1, _amount);
            return;
        }

        // Pseudorandomization
        uint256 remainingTier1 = tier1Available;
        uint256 remainingTier2 = tier2Available;

        uint256 tier1ToMint = 0;
        uint256 tier2ToMint = 0;
        for (uint256 i = 0; i < _amount; i++) {
            if (remainingTier1 == 0) {
                uint256 remainder = (_amount - i);
                tier2ToMint += remainder;
                break;
            }
            if (remainingTier2 == 0) {
                uint256 remainder = (_amount - i);
                tier1ToMint += remainder;
                break;
            }
            uint256 random = generatePseudoRandomNumber(
                remainingTier1 + remainingTier2
            ) % (remainingTier1 + remainingTier2);
            if (random <= remainingTier1) {
                tier1ToMint++;
                remainingTier1--;
            } else {
                tier2ToMint++;
                remainingTier2--;
            }
        }

        if (tier1ToMint > 0) {
            tokenContract.mint(_to, TOKEN_ID_TIER_1, tier1ToMint);
        }

        if (tier2ToMint > 0) {
            tokenContract.mint(_to, TOKEN_ID_TIER_2, tier2ToMint);
        }
    }

    function generatePseudoRandomNumber(uint256 nonce)
        private
        view
        returns (uint256)
    {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.number,
                        block.basefee,
                        _msgSender(),
                        nonce
                    )
                )
            );
    }

    function setSignatureRequired(bool _signatureRequired)
        public
        onlyAuthorized
    {
        signatureRequired = _signatureRequired;
    }

    function setNativeSalePrice(uint256 _nativeSalePrice)
        public
        onlyAuthorized
    {
        nativeSalePrice = _nativeSalePrice;
    }

    function setTokenSalePrice(uint256 _tokenSalePrice) public onlyAuthorized {
        tokenSalePrice = _tokenSalePrice;
    }

    function setSaleActive(bool _saleActive) public onlyAuthorized {
        require(preminted, "Must premint before sale");
        saleActive = _saleActive;
    }

    function getMintsPerAddress(address _to) public view returns (uint256) {
        return mintsPerAddress[_to];
    }

    function setMintingSigner(address _signer) public onlyAuthorized {
        _setMintingSigner(_signer);
    }

    function setWalletLimit(uint256 _walletLimit) public onlyAuthorized {
        walletLimit = _walletLimit;
    }

    function setVaultAddress(address _vaultAddress) public onlyAuthorized {
        require(_vaultAddress != address(0), "Invalid vault address");
        vaultAddress = _vaultAddress;
    }

    function setPremintAddress(address _premintAddress) public onlyAuthorized {
        require(_premintAddress != address(0), "Invalid premint address");
        premintAddress = _premintAddress;
    }

    function setTokenURI(uint256 tokenId, string calldata uri)
        public
        onlyAuthorized
    {
        tokenContract.setURI(tokenId, uri);
    }

    function withdraw() public onlyAuthorized {
        Address.sendValue(payable(vaultAddress), address(this).balance);
    }

    function withdrawPaymentToken() public onlyAuthorized {
        uint256 balance = paymentTokenContract.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        paymentTokenContract.transfer(vaultAddress, balance);
    }

    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    function validateAuthorized() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
    }

    modifier saleNotActive() {
        validateSaleNotActive();
        _;
    }

    function validateSaleNotActive() private view {
        require(!saleActive, "Sale is active");
    }
}
