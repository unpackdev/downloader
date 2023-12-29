// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//

import "./Ownable.sol";
import "./types.sol";

// import "./console.sol";
// import "./IERC20.sol";
// import "./DevRescuableOnTestnets.sol";

struct ConfirmationInfo {
  uint128 number;
  uint64 timestamp;
}

// Contract which represents the oracles their confirmations.
contract ConfirmationsV1 is Ownable, ConfirmationsResolver {
  // Hash of the last confirmation
  bytes32 private head;

  // Address of the oracle gate which is allowed to finalize confirmations
  address private oracleGate;

  // Amount of blocks the blockchain has evolved before another finalization is accepted.
  uint32 private finalizeBlockDiffMin;

  // Block height of the last finalization we received, parsed from the request, checked against current block height.
  uint64 private lastFinalizeAtBlockHeight;

  // Mapping of confirmations which are finalized
  mapping(bytes32 => ConfirmationInfo) private confirmations;

  // Emitted whenever the config has been changed
  event ConfigChanged(address indexed oracleGate, uint32 finalizeBlockDiffMin);

  // Emitted whenever a confirmation is finalized (claims work from finalization)
  event ConfirmationFinalized (
    bytes32 indexed confirmationHash,
    uint128 indexed number,
    bytes32 stateRoot,
    bytes32 parentHash,
    uint64 timestamp,
    bytes32 bundleHash,
    bytes32 indexed closerHash,
    uint32 blockCount,
    bytes32 blockHash,
    uint64 confirmChainBlockNr
  );

  function finalize(
    bytes32 confirmationHash,
    uint128 number,
    bytes32 stateRoot,
    bytes32 parentHash,
    uint64 timestamp,
    bytes32 bundleHash,
    bytes32 closerHash,
    uint32 blockCount,
    bytes32 blockHash,
    uint64 confirmChainBlockNr
  ) external onlyOracleGate {
    require(
      // Ensure this finalization has not yet been done before
      confirmations[confirmationHash].number == 0 
      // Verify that the confirmations form a clean chain
      && number == confirmations[head].number + 1 
      && (number > 1 ? head == parentHash : true)
      // Verify that there is sufficient blocks in between the finalization requests.
      // In a deployment which behaves periodically and is synced, this will enforce 24hr delay between tip of the confirmation chain finalizations.
      && (confirmChainBlockNr < block.number && (lastFinalizeAtBlockHeight + finalizeBlockDiffMin) <= confirmChainBlockNr)
      , "400: nochain");

    confirmations[confirmationHash] = ConfirmationInfo(number, timestamp);
    head = confirmationHash;

    // Store new block finalization offset
    lastFinalizeAtBlockHeight = confirmChainBlockNr;

    emit ConfirmationFinalized(confirmationHash, number, stateRoot, parentHash, timestamp, bundleHash, closerHash, blockCount, blockHash, confirmChainBlockNr);
  }

  function getHead() external view override returns (bytes32) {
    return head;
  }

  function getConfirmation(bytes32 confirmationHash) external view override returns(uint128 number, uint64 timestamp) {
    return (confirmations[confirmationHash].number, confirmations[confirmationHash].timestamp);
  }

  function getOracleGate() external view returns (address) {
    return oracleGate;
  }

  function configure(address oracleGate_, uint32 finalizeBlockDiffMin_) external onlyOwner {
    require(oracleGate_ != address(0) && finalizeBlockDiffMin_ > 0, "400");
    oracleGate = oracleGate_;
    finalizeBlockDiffMin = finalizeBlockDiffMin_;
    emit ConfigChanged(oracleGate_, finalizeBlockDiffMin_);
  }

  // -- MODIFIERS
  modifier onlyOracleGate {
    require(oracleGate == msg.sender, "401");
    _;
  }
  
  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}