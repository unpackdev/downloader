//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./ERC721.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

// Token Backed NFTs
contract TBNTokenERC721 is ERC721Pausable, AccessControl, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;
  Counters.Counter private _tokenIds;

  bytes32 public constant ADMIN = keccak256("ADMIN");
  address public treasuryAddress;

  struct TokenData {
    address tokenAddress;
    uint256 tokenAmount;
  }

  mapping(uint256 => TokenData) public nftsToTokenData;

  event TBNTokenERC721Mint(
    uint256 tokenId,
    uint256 timestamp,
    uint256 tbnTokenAmount,
    address tbnTokenAddress,
    address account
  );

  event TBNTokenERC721Redeem(
    uint256 tokenId,
    uint256 timestamp,
    uint256 tbnTokenAmount,
    address tbnTokenAddress,
    address account
  );

  constructor(
    address _admin,
    address _treasury,
    string memory _tokenName,
    string memory _tokenAlias,
    string memory _baseUri
  ) public ERC721(_tokenName, _tokenAlias) {
    _setupRole(ADMIN, _admin);
    _setRoleAdmin(ADMIN, ADMIN);
    _setBaseURI(_baseUri);
    treasuryAddress = _treasury;
  }

  function setBaseUri(string memory newBaseURI) public {
    require(
      hasRole(ADMIN, _msgSender()),
      "You must be the admin to set a new base URI"
    );
    _setBaseURI(newBaseURI);
  }

  /**
    redeem the tokens in the owned Token Based NFT by tokenId
    TBN will be burned after redemtion
  */
  function redeem(uint256 tokenId) public nonReentrant {
    require(
      ownerOf(tokenId) == msg.sender,
      "You must be the owner of the NFT in order to redeem tokens"
    );
    uint256 amount = nftsToTokenData[tokenId].tokenAmount;
    require(amount > 0, "You have no tokens available to transfer");
    nftsToTokenData[tokenId].tokenAmount = 0;

    address tbnTokenAddress = nftsToTokenData[tokenId].tokenAddress;
    if (tbnTokenAddress == address(0)) {
      msg.sender.transfer(amount);
    } else {
      IERC20 token = IERC20(tbnTokenAddress);

      token.safeTransfer(msg.sender, amount);
    }

    _burn(tokenId);

    emit TBNTokenERC721Redeem(
      tokenId,
      block.timestamp,
      amount,
      tbnTokenAddress,
      msg.sender
    );
  }

  /**
    Mint a Token Based NFT containing paymentTokenAmount amount of token paymentTokenAddress
  */
  function mint(address paymentTokenAddress, uint256 paymentTokenAmount)
    public
    payable
    returns (uint256)
  {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    uint256 tokensReceived = paymentTokenAmount;

    if (paymentTokenAddress == address(0)) {
      require(msg.value == paymentTokenAmount, "Incorrect transaction value.");
    } else {
      IERC20 token = IERC20(paymentTokenAddress);

      uint256 tokensBefore = token.balanceOf(address(this));

      token.transferFrom(msg.sender, address(this), paymentTokenAmount);

      uint256 tokensAfter = token.balanceOf(address(this));

      /**
                This is for the case when some tokens take a comission. Since transactions run
                concurrently we can check for the amount of tokens the contract has before and after
                and use the difference as the amount of tokens in this Token Backed NFT.
            */
      tokensReceived = tokensAfter - tokensBefore;
    }

    _safeMint(msg.sender, tokenId);

    nftsToTokenData[tokenId] = TokenData(paymentTokenAddress, tokensReceived);

    emit TBNTokenERC721Mint(
      tokenId,
      block.timestamp,
      tokensReceived,
      paymentTokenAddress,
      msg.sender
    );
  }

  function pause() public {
    require(hasRole(ADMIN, _msgSender()), "You must be the admin to pause");
    _pause();
  }

  function unpause() public {
    require(hasRole(ADMIN, _msgSender()), "You must be the admin to unpause");
    _unpause();
  }
}
