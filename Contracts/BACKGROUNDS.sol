// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BACKGROUNDS {

    string _header = "w";

    function getBackground (uint32 _traitId) public pure returns (string [2] memory) {

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
        return ["", ""];

    }
}