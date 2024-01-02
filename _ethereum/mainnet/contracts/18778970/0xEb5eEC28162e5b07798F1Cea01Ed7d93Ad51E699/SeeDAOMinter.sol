// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ISeeDAOMinter.sol";
import "./ISeeDAORegistrarController.sol";
import "./IPriceOracle.sol";

contract SeeDAOMinter is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  ISeeDAOMinter
{
  ISeeDAORegistrarController public registrarController;

  // enable/disable register feature
  bool public registrable;
  // enable/disable register with whitelist feature
  bool public registrableWithWhitelist;

  // store the merkle root hash of whitelist
  mapping(uint256 => bytes32) public whitelistRootHashes;
  // user can only register once with whitelist
  mapping(address => bool) public registeredWithWhitelist;

  // ERC20 condition
  address public condERC20;
  uint256 public condERC20Balance;
  // ERC721 condition
  address public condERC721;
  uint256 public condERC721Balance;
  // ERC1155 condition
  address public condERC1155;
  uint256 public condERC1155TokenId;
  uint256 public condERC1155Balance;

  // payment recipient address
  address public paymentRecipient;
  // price of native token
  uint256 public priceOfNative;
  // price of ERC20 token
  address public paymentERC20;
  uint256 public priceOfERC20;
  // price from oracle
  IPriceOracle public priceOracle;

  modifier onlyRegistrable() {
    require(registrable, "Not registrable");
    _;
  }

  modifier onlyRegistrableWithWhitelist() {
    require(registrableWithWhitelist, "Not registrable with whitelist");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    ISeeDAORegistrarController _registrarController,
    address _paymentRecipient
  ) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();

    registrarController = _registrarController;
    paymentRecipient = _paymentRecipient;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function register(
    string memory name,
    address resolver,
    bytes32 secret,
    address payERC20Token
  ) external payable onlyRegistrable nonReentrant {
    // ---------------- asserts condition ----------------
    // ERC20 condition
    if (condERC20 != address(0)) {
      require(condERC20Balance > 0, "ERC20 balance condition is not set");
      if (
        IERC20Upgradeable(condERC20).balanceOf(_msgSender()) < condERC20Balance
      ) {
        revert InsufficientERC20Balance();
      }
    }

    // ERC721 condition
    if (condERC721 != address(0)) {
      require(condERC721Balance > 0, "ERC721 balance condition is not set");
      if (
        IERC721Upgradeable(condERC721).balanceOf(_msgSender()) <
        condERC721Balance
      ) {
        revert InsufficientERC721Balance();
      }
    }

    // ERC1155 condition
    if (condERC1155 != address(0)) {
      require(condERC1155Balance > 0, "ERC1155 balance condition is not set");
      if (
        IERC1155Upgradeable(condERC1155).balanceOf(
          _msgSender(),
          condERC1155TokenId
        ) < condERC1155Balance
      ) {
        revert InsufficientERC1155Balance();
      }
    }
    // ---------------- asserts condition ----------------

    // ---------------- payable ----------------
    if (priceOracle == IPriceOracle(address(0))) {
      // >>>> payable price from this contract

      // !! ERC20 payment has high priority than native token payment
      if (priceOfERC20 != 0) {
        // -->> pay with ERC20 token

        require(paymentERC20 != address(0), "payment ERC20 token is not set");
        // check if allowance is enough
        if (
          IERC20Upgradeable(paymentERC20).allowance(
            _msgSender(),
            address(this)
          ) < priceOfERC20
        ) {
          revert InsufficientAllowance();
        }

        // transfer ERC20 token from msg.sender to paymentRecipient
        IERC20Upgradeable(paymentERC20).transferFrom(
          _msgSender(),
          paymentRecipient,
          priceOfERC20
        );
      } else {
        // -->> pay with native token

        if (priceOfNative != 0) {
          // check if payment is enough
          if (msg.value < priceOfNative) {
            revert InsufficientPayment();
          }

          // transfer native token from msg.sender to paymentRecipient
          payable(paymentRecipient).transfer(priceOfNative);

          // refund the extra native token
          if (msg.value > priceOfNative) {
            payable(_msgSender()).transfer(msg.value - priceOfNative);
          }
        }
      }
    } else {
      // >>>> payable price from oracle

      uint256 tokenId = registrarController.nextTokenId();
      uint256 erc20Price = priceOracle.erc20Price(name, tokenId, payERC20Token);
      uint256 nativePrice = priceOracle.nativePrice(name, tokenId);

      // check if oracle price is set
      require(erc20Price != 0 || nativePrice != 0, "Oracle price is not set");

      // !! ERC20 payment has high priority than native token payment
      if (erc20Price != 0) {
        // -->> pay with ERC20 token

        // check if allowance is enough
        if (
          IERC20Upgradeable(payERC20Token).allowance(
            _msgSender(),
            address(this)
          ) < erc20Price
        ) {
          revert InsufficientAllowance();
        }

        // transfer ERC20 token from msg.sender to paymentRecipient
        IERC20Upgradeable(payERC20Token).transferFrom(
          _msgSender(),
          paymentRecipient,
          erc20Price
        );
      } else {
        // -->> pay with native token

        if (nativePrice != 0) {
          // check if payment is enough
          if (msg.value < nativePrice) {
            revert InsufficientPayment();
          }

          // transfer native token from msg.sender to paymentRecipient
          payable(paymentRecipient).transfer(nativePrice);

          // refund the extra native token
          if (msg.value > nativePrice) {
            payable(_msgSender()).transfer(msg.value - nativePrice);
          }
        }
      }
    }
    // ---------------- payable ----------------

    // register SNS
    registrarController.registerWithCommitment(
      name,
      _msgSender(),
      resolver,
      secret
    );
  }

  function registerWithWhitelist(
    string memory name,
    address resolver,
    bytes32 secret,
    uint256 whitelistId,
    bytes32[] calldata proof
  ) external onlyRegistrableWithWhitelist nonReentrant {
    require(
      _verifyWhitelist(whitelistId, proof, _msgSender()),
      "You are not in the whitelist"
    );
    require(
      !registeredWithWhitelist[_msgSender()],
      "You have registered with whitelist"
    );

    // register SNS
    registrarController.registerWithCommitment(
      name,
      _msgSender(),
      resolver,
      secret
    );

    // set registered with whitelist flag to true
    registeredWithWhitelist[_msgSender()] = true;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev verify whether an address is in the whitelist
  function _verifyWhitelist(
    uint256 whitelistId,
    bytes32[] calldata proof,
    address addr
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
    return
      MerkleProofUpgradeable.verify(
        proof,
        whitelistRootHashes[whitelistId],
        leaf
      );
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function setRegistrarController(
    ISeeDAORegistrarController _registrarController
  ) external onlyOwner {
    registrarController = _registrarController;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function enableRegister() external onlyOwner {
    registrable = true;
  }

  function disableRegister() external onlyOwner {
    registrable = false;
  }

  function enableRegisterWithWhitelist() external onlyOwner {
    registrableWithWhitelist = true;
  }

  function disableRegisterWithWhitelist() external onlyOwner {
    registrableWithWhitelist = false;
  }

  function setWhitelist(
    uint256 whitelistId,
    bytes32 rootHash
  ) external onlyOwner {
    whitelistRootHashes[whitelistId] = rootHash;
    emit WhitelistAdd(whitelistId, rootHash);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function setCondERC20(address _condERC20) external onlyOwner {
    condERC20 = _condERC20;
  }

  function setCondERC20Balance(uint256 _condERC20Balance) external onlyOwner {
    condERC20Balance = _condERC20Balance;
  }

  function setCondERC20AndBalance(
    address _condERC20,
    uint256 _condERC20Balance
  ) external onlyOwner {
    condERC20 = _condERC20;
    condERC20Balance = _condERC20Balance;
  }

  function setCondERC721(address _condERC721) external onlyOwner {
    condERC721 = _condERC721;
  }

  // must contain decimals, for example: `setCondERC721Balance(ethers.parseUnits("5", 18))`
  function setCondERC721Balance(uint256 _condERC721Balance) external onlyOwner {
    condERC721Balance = _condERC721Balance;
  }

  function setCondERC721AndBalance(
    address _condERC721,
    uint256 _condERC721Balance
  ) external onlyOwner {
    condERC721 = _condERC721;
    condERC721Balance = _condERC721Balance;
  }

  function setCondERC1155(address _condERC1155) external onlyOwner {
    condERC1155 = _condERC1155;
  }

  function setCondERC1155TokenIdAndBalance(
    uint256 _condERC1155TokenId,
    uint256 _condERC1155Balance
  ) external onlyOwner {
    condERC1155TokenId = _condERC1155TokenId;
    condERC1155Balance = _condERC1155Balance;
  }

  function setCondERC1155AndTokenIdAndBalance(
    address _condERC1155,
    uint256 _condERC1155TokenId,
    uint256 _condERC1155Balance
  ) external onlyOwner {
    condERC1155 = _condERC1155;
    condERC1155TokenId = _condERC1155TokenId;
    condERC1155Balance = _condERC1155Balance;
  }

  // set payment recipient address
  function setPaymentRecipient(address _paymentRecipient) external onlyOwner {
    paymentRecipient = _paymentRecipient;
  }

  // set price of native token
  // must contain decimals, for example: `setPrice(ethers.parseEther("0.005"))`
  function setPriceOfNative(uint256 _priceOfNative) external onlyOwner {
    priceOfNative = _priceOfNative;
  }

  // set price of ERC20 token
  // must contain decimals, for example: `setPriceOfERC20(ethers.parseUnits("5", 18))`
  function setPriceOfERC20(
    address _paymentERC20,
    uint256 _priceOfERC20
  ) external onlyOwner {
    paymentERC20 = _paymentERC20;
    priceOfERC20 = _priceOfERC20;
  }

  // set price oracle
  function setPriceOracle(IPriceOracle _priceOracle) external onlyOwner {
    priceOracle = _priceOracle;
  }
}
