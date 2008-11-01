Feature: Simple usage
  TwoWaySQL simple feature description

  Scenario: merge context with template
    Given template is "SELECT * FROM emp WHERE job = /*ctx[:job]*/'CLERK'"
    And modify context "ctx[:job] = 'MANAGER'"
    When the template is merged with context
    Then merged sql should be "SELECT * FROM emp WHERE job = ?"
    And bound variables should be "['MANAGER']"
