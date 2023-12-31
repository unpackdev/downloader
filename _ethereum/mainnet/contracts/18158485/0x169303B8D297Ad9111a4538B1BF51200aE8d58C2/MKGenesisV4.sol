// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./MKGenesisV2Flattened.sol";

/*
                       j╫╫╫╫╫╫ ]╫╫╫╫╫H                                          
                        ```╫╫╫ ]╫╫````                                          
    ▄▄▄▄      ▄▄▄▄  ÑÑÑÑÑÑÑ╫╫╫ ]╫╫ÑÑÑÑÑÑÑH ▄▄▄▄                                 
   ▐████      ████⌐ `````````` ``````````  ████▌                                
   ▐█████▌  ▐█████⌐▐██████████ ╫█████████▌ ████▌▐████ ▐██████████ ████▌ ████▌   
   ▐██████████████⌐▐████Γ▐████ ╫███▌└████▌ ████▌ ████ ▐████│█████ ████▌ ████▌   
   ▐████▀████▀████⌐▐████ ▐████ ╫███▌ ████▌ █████████▄ ▐██████████ ████▌ ████▌   
   ▐████ ▐██▌ ████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████│││││└ ██████████▌   
   ▐████      ████⌐▐██████████ ╫███▌ ████▌ ████▌▐████ ▐██████████ ▀▀▀▀▀▀████▌   
    ''''      ''''  '''''''''' `'''  `'''  ''''  ''''  '''''''''` ██████████▌   
╓╓╓╓  ╓╓╓╓  ╓╓╓╓                              .╓╓╓╓               ▀▀▀▀▀▀▀▀▀▀Γ   ===
████▌ ████=▐████                              ▐████                             
████▌ ████= ▄▄▄▄ ▐█████████▌ ██████████▌▐██████████ ║█████████▌ ███████▌▄███████
█████▄███▀ ▐████ ▐████▀████▌ ████▌▀████▌▐████▀▀████ ║████▀████▌ ████▌▀████▀▀████
█████▀████⌐▐████ ▐████ ╫███▌ ████▌ ████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ █████▄████▌▐████ ▐████ ║████ ████▌ ████▌ ████=▐████
████▌ ████=▐████ ▐████ ╫███▌ ▀▀▀▀▀▀████▌▐██████████ ║█████████▌ ████▌ ████=▐████
▀▀▀▀` ▀▀▀▀  └└└└ `▀▀▀▀ "▀▀▀╘ ▄▄▄▄▄▄████▌ ▀▀▀▀▀▀▀▀▀▀ `▀▀▀▀▀▀▀▀▀└ ▀▀▀▀` ▀▀▀▀  ▀▀▀▀
                             ▀▀▀▀▀▀▀▀▀▀U                                      
*/

contract MKGenesisV4 is MKGenesisV2Flattened {
    bool public dbMigrationComplete; // false by default

    function setDbMigrationComplete() public onlyOwner {
        dbMigrationComplete = true;
    }

    function migrateDB(
        address[] calldata owner,
        uint256 offset
    ) public onlyOwner {
        unchecked {
            require(dbMigrationComplete == false, "DB migration completed");
            uint256 i;
            do {
                address to = owner[i];
                _balances[to] += 1;
                _owners[i + offset] = to;
                emit Transfer(address(0), to, i + offset);
            } while (++i < owner.length);
        }
    }

    function migrateDBLocks(uint256[] calldata tokenIds) public onlyOwner {
        unchecked {
            require(dbMigrationComplete == false, "DB migration completed");
            uint256 i;
            do {
                locks[tokenIds[i]].push(
                    0xa390c5787bB318132644559053d1d036c1C4b0e4
                );
            } while (++i < tokenIds.length);
        }
    }

    address constant TREASURY = 0x21CdBb13A1C539c83a7848b51bEEc8A3297B9E1B;

    function migrateOtherMKs(uint256[] calldata tokenIds) public onlyOwner {
        unchecked {
            uint256 i;
            uint256 tokenId;
            do {
                tokenId = tokenIds[i];
                emit Transfer(address(0), TREASURY, tokenId);
                _owners[tokenId] = TREASURY;
            } while (++i < tokenIds.length);
            _balances[TREASURY] += tokenIds.length;
        }
    }
}
