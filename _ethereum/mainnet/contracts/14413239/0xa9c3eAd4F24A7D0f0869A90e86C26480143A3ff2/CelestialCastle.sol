// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Interfaces.sol";

/**
 * @title Celestial Castle
 * @notice Edited from EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialCastle is Ownable, IERC721Receiver {
  bool public isTravelEnabled;
  /// @notice Celestial portal contract.
  PortalLike public portal;
  /// @notice Freaks N Guilds token contract.
  IFnG public freaksNGuilds;
  /// @notice Freaks bucks token contract.
  IFBX public freaksBucks;

  /// @notice Contract address to it's reflection.
  mapping(address => address) public reflection;
  /// @notice Original token id owner.
  mapping(uint256 => address) public ownerOf;

  /// @notice Require that the sender is the portal for bridging operations.
  modifier onlyPortal() {
    require(msg.sender == address(portal), "CelestialCastle: sender is not the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(
    address newPortal,
    address newFreaksNGuilds,
    address newFreaksBucks,
    bool newIsTravelEnabled
  ) external onlyOwner {
    portal = PortalLike(newPortal);
    freaksNGuilds = IFnG(newFreaksNGuilds);
    freaksBucks = IFBX(newFreaksBucks);
    isTravelEnabled = newIsTravelEnabled;
  }

  /// @notice Travel tokens to L2.
  function travel(
    uint256[] calldata freakIds,
    uint256[] calldata celestialIds,
    uint256 fbxAmount
  ) external {
    require(isTravelEnabled, "CelestialCastle: travel is disabled");
    bytes[] memory calls = new bytes[](
      (freakIds.length > 0 ? 1 : 0) + (celestialIds.length > 0 ? 1 : 0) + (fbxAmount > 0 ? 1 : 0)
    );
    uint256 callsIndex = 0;

    if (freakIds.length > 0) {
      Freak[] memory freaks = new Freak[](freakIds.length);
      for (uint256 i = 0; i < freakIds.length; i++) {
        require(ownerOf[freakIds[i]] == address(0), "CelestialCastle: token already staked");
        require(freaksNGuilds.isFreak(freakIds[i]), "CelestialCastle: not a freak");
        ownerOf[freakIds[i]] = msg.sender;
        freaks[i] = freaksNGuilds.getFreakAttributes(freakIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), freakIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveFreakIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        freakIds,
        freaks
      );
      callsIndex++;
    }

    if (celestialIds.length > 0) {
      Celestial[] memory celestials = new Celestial[](celestialIds.length);
      for (uint256 i = 0; i < celestialIds.length; i++) {
        require(ownerOf[celestialIds[i]] == address(0), "CelestialCastle: token already staked");
        require(!freaksNGuilds.isFreak(celestialIds[i]), "CelestialCastle: not a celestial");
        ownerOf[celestialIds[i]] = msg.sender;
        celestials[i] = freaksNGuilds.getCelestialAttributes(celestialIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), celestialIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveCelestialIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        celestialIds,
        celestials
      );
      callsIndex++;
    }

    if (fbxAmount > 0) {
      freaksBucks.burn(msg.sender, fbxAmount);
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveBucks.selector,
        reflection[address(freaksBucks)],
        msg.sender,
        fbxAmount
      );
    }

    portal.sendMessage(abi.encode(reflection[address(this)], calls));
  }

  /// @notice Retrieve freaks from castle when bridging.
  function retrieveFreakIds(
    address fng,
    address owner,
    uint256[] calldata freakIds,
    Freak[] calldata freakAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < freakIds.length; i++) {
      delete ownerOf[freakIds[i]];
      IFnG(fng).transferFrom(address(this), owner, freakIds[i]);
      IFnG(fng).setFreakAttributes(freakIds[i], freakAttributes[i]);
    }
  }

  /// @notice Retrieve celestials from castle when bridging.
  function retrieveCelestialIds(
    address fng,
    address owner,
    uint256[] calldata celestialIds,
    Celestial[] calldata celestialAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < celestialIds.length; i++) {
      delete ownerOf[celestialIds[i]];
      IFnG(fng).transferFrom(address(this), owner, celestialIds[i]);
      IFnG(fng).setCelestialAttributes(celestialIds[i], celestialAttributes[i]);
    }
  }

  // function callFnG(bytes calldata data) external onlyPortal {
  //   (bool succ, ) = freaksNGuilds.call(data)
  // }

  /// @notice Retrive freaks bucks to `owner` when bridging.
  function retrieveBucks(
    address fbx,
    address owner,
    uint256 value
  ) external onlyPortal {
    IFBX(fbx).mint(owner, value);
  }

  /// @notice Set contract reflection address on L2.
  function setReflection(address key, address value) external onlyOwner {
    reflection[key] = value;
    reflection[value] = key;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function setIsTravelEnabled(bool newIsTravelEnabled) external onlyOwner {
    isTravelEnabled = newIsTravelEnabled;
  }

      /// @notice Withdraw `amount` of ether to msg.sender.
  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice Withdraw `tokenId` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
  }
}



