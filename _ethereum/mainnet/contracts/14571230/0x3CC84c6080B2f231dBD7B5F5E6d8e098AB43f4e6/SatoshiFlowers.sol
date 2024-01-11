//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

// ╭━━━╮  ╭╮      ╭╮   ╭━━━┳╮
// ┃╭━╮┃ ╭╯╰╮     ┃┃   ┃╭━━┫┃
// ┃╰━━┳━┻╮╭╋━━┳━━┫╰━┳╮┃╰━━┫┃╭━━┳╮╭╮╭┳━━┳━┳━━╮
// ╰━━╮┃╭╮┃┃┃╭╮┃━━┫╭╮┣┫┃╭━━┫┃┃╭╮┃╰╯╰╯┃┃━┫╭┫━━┫
// ┃╰━╯┃╭╮┃╰┫╰╯┣━━┃┃┃┃┃┃┃  ┃╰┫╰╯┣╮╭╮╭┫┃━┫┃┣━━┃
// ╰━━━┻╯╰┻━┻━━┻━━┻╯╰┻╯╰╯  ╰━┻━━╯╰╯╰╯╰━━┻╯╰━━╯

import "./SatoshiConfig.sol";

/// @title Satoshi Flowers NFT Collection Configuration
/// @author Mouradif
contract SatoshiFlowers is SatoshiFlowersConfig {

  /// @notice Free Mint for the lucky few
  /// @param signature The address of the caller signed by a FREEMINT_APPROVER wallet
  function freeMint(bytes calldata signature)
    public
    hasSupply(1)
    isApproved(signature, FREEMINT_APPROVER)
    isWithinMintLimit(_freemints, FREEMINT_SUPPLY)
  {
    require(block.number >= PUBLIC_START_BLOCK, "Free Mint has not started");
    require(!freemintClosed(), "Free Mint is over");
    require(!_freeMintClaimed[msg.sender], "You have already claimed your free mint");

    _freeMintClaimed[msg.sender] = true;
    _totalMints[msg.sender] += 1;
    _freemints += 1;
    _safeMint(msg.sender, 1);
  }

  /// @notice Private Mint for the early birds who got a spot in the whitelist
  /// @param quantity The number of NFTs to mint (max 3)
  /// @param signature The address of the caller signed by a FREEMINT_APPROVER wallet
  function privateMint(uint256 quantity, bytes calldata signature)
    public
    payable
    hasSupplyOutsideReserve(quantity)
    isApproved(signature, PRIVATEMINT_APPROVER)
    isWithinMintLimit(_presaleMints[msg.sender] + quantity, PRESALE_MAX_MINT)
    isWithinMintLimit(_totalMints[msg.sender] + quantity, TOTAL_MAX_MINT)
    hasTheRightAmount(PRESALE_PRICE * quantity)
  {
    require(block.number >= PRESALE_START_BLOCK, "Presale has not started");

    _totalMints[msg.sender] += quantity;
    _presaleMints[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  /// @notice Public Mint for everyone
  /// @param quantity The number of NFTs to mint (max 3)
  function publicMint(uint256 quantity)
    public
    payable
    hasSupplyOutsideReserve(quantity)
    isWithinMintLimit(quantity, PUBLIC_MAX_MINT)
    isWithinMintLimit(_totalMints[msg.sender] + quantity, TOTAL_MAX_MINT)
    hasTheRightAmount(PUBLIC_PRICE * quantity)
  {
    require(block.number >= PUBLIC_START_BLOCK, "Public sale has not started");

    _totalMints[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }
}
