Feature: Simple usage
  TwoWaySQL simple feature description

  Scenario Outline: merge context with template
    Given template is <template>
    And modify context <context>
    When template merged with context
    Then merged sql should be <sql>
    And bound variables should be <bound_variables>

  Examples:
    | template           | context | sql               | bound_variables |
    | SELECT * FROM emp  |         | SELECT * FROM emp | []              |
    | SELECT * FROM emp WHERE job = /*ctx[:job]*/'CLERK' | ctx[:job] = 'MANAGER' | SELECT * FROM emp WHERE job = ? | ['MANAGER'] |
    | SELECT * FROM emp WHERE age < /*ctx[:age]*/30 | ctx[:age] = 25 | SELECT * FROM emp WHERE age < ? | [25] |
