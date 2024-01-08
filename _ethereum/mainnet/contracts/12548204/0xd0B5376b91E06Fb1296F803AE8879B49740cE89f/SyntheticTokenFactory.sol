// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./IFinder.sol";
import "./IFactoryVersioning.sol";
import "./MintableBurnableIERC20.sol";
import "./Constants.sol";
import "./MintableBurnableTokenFactory.sol";

contract SynthereumSyntheticTokenFactory is MintableBurnableTokenFactory {
  //----------------------------------------
  // Storage
  //----------------------------------------

  ISynthereumFinder public synthereumFinder;

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyDerivativeFactory() {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.FactoryVersioning
        )
      );
    uint256 numberOfFactories =
      factoryVersioning.numberOfVerisonsOfFactory(
        FactoryInterfaces.DerivativeFactory
      );
    uint256 counter = 0;
    for (uint8 i = 0; counter < numberOfFactories; i++) {
      try
        factoryVersioning.getFactoryVersion(
          FactoryInterfaces.DerivativeFactory,
          i
        )
      returns (address factory) {
        if (msg.sender == factory) {
          _;
          break;
        } else {
          counter++;
        }
      } catch {}
    }
    if (numberOfFactories == counter) {
      revert('Sender must be a derivative factory');
    }
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs SynthereumSyntheticTokenFactory contract
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(address _synthereumFinder) public {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  /**
   * @notice Create a new synthetic token and return it to the caller.
   * @dev The caller will become the only minter and burner and the new owner capable of assigning the roles.
   * @param tokenName used to describe the new token.
   * @param tokenSymbol short ticker abbreviation of the name. Ideally < 5 chars.
   * @param tokenDecimals used to define the precision used in the token's numerical representation.
   * @return newToken an instance of the newly created token
   */
  function createToken(
    string calldata tokenName,
    string calldata tokenSymbol,
    uint8 tokenDecimals
  )
    public
    override
    onlyDerivativeFactory
    returns (MintableBurnableIERC20 newToken)
  {
    newToken = super.createToken(tokenName, tokenSymbol, tokenDecimals);
  }
}
