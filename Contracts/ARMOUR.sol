// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GladiatorsXIII.sol";

contract ARMOUR is GladiatorsXIII{

    string _header = "w";

    function getArmour (uint32 _traitId, uint256 tokenId_) public pure returns (string [2] memory) {

        
        if (_traitId == 0) {
            return ["", ""];
        }
        if (_traitId == 1) {
            return ["", ""];
        }
        if (_traitId == 2) {
            return ["", ""];
        }
        if (_traitId == 3) {
            return ["", ""];
        }
        if (_traitId == 4) {
            return ["", ""];
        }
        if (_traitId == 5) {
            return ["", ""];
        }
        if (_traitId == 6) {
            return ["", ""];
        }
        if (_traitId == 7) {
            return ["", ""];
        }

        return ["", ""];

    }
}