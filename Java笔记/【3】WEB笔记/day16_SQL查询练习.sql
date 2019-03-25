单表查询
/*
1. 查询出部门编号为30的所有员工
2. 所有销售员的姓名、编号和部门编号。
3. 找出奖金高于工资的员工。
4. 找出奖金高于工资60%的员工。
5. 找出部门编号为10中所有经理，和部门编号为20中所有销售员的详细资料。

6. 找出部门编号为10中所有经理，部门编号为20中所有销售员，还有即不是经理又不是销售员但其工资大或等于20000的所有员工详细资料。
8. 无奖金或奖金低于1000的员工。
9. 查询名字由三个字组成的员工。
10.查询2000年入职的员工。
11. 查询所有员工详细信息，用编号升序排序
12. 查询所有员工详细信息，用工资降序排序，如果工资相同使用入职日期升序排序
13. 查询每个部门的平均工资
14. 查询每个部门的雇员数量。 
15. 查询每种工作的最高工资、最低工资、人数
*/
-- 1. 查询出部门编号为30的所有员工
SELECT * FROM emp WHERE deptno=30;

-- 2. 所有销售员的姓名、编号和部门编号。
SELECT empno,ename,deptno FROM emp WHERE job='销售员';

-- 3. 找出奖金高于工资的员工。
SELECT * FROM emp WHERE COMM>sal;

-- 4. 找出奖金高于工资60%的员工。
SELECT * FROM emp WHERE COMM>sal*0.6;

-- 5. 找出部门编号为10中所有经理，和部门编号为20中所有销售员的详细资料。
SELECT * FROM emp WHERE (deptno=10 AND job='经理') OR (deptno=20 AND job='销售员');

-- 6. 找出部门编号为10中所有经理，部门编号为20中所有销售员，
-- 还有即不是经理又不是销售员但其工资大或等于20000的所有员工详细资料。
SELECT * FROM emp WHERE (deptno=10 AND job='经理') OR (deptno=20 AND job='销售员') 
OR (job NOT IN ('经理','销售员') AND sal>20000);

-- 8. 无奖金或奖金低于1000的员工。
SELECT * FROM emp WHERE COMM<=1000 OR COMM IS NULL;

-- 9. 查询名字由三个字组成的员工。
SELECT * FROM emp WHERE ename LIKE '___';

-- 10.查询2000年入职的员工。
SELECT * FROM emp WHERE hiredate LIKE '2000-%';

-- 11. 查询所有员工详细信息，用编号升序排序
SELECT * FROM emp ORDER BY empno ASC;

-- 12. 查询所有员工详细信息，用工资降序排序，如果工资相同使用入职日期升序排序
SELECT * FROM emp ORDER BY sal DESC , hiredate ASC;

-- 13. 查询每个部门的平均工资
SELECT deptno,AVG(sal) AS avg_sal FROM emp GROUP BY deptno ;

-- 14. 查询每个部门的雇员数量。 
SELECT deptno,COUNT(*) FROM emp GROUP BY deptno;

-- 15. 查询每种工作的最高工资、最低工资、人数
SELECT deptno,MAX(sal),MIN(sal),COUNT(*) FROM emp GROUP BY deptno;

多表查询
-- 1. 查出至少有一个员工的部门。显示部门编号、部门名称、部门位置、部门人数。
SELECT d.*,COUNT(*) FROM dept d,emp e
WHERE d.`deptno`=e.`deptno`
GROUP BY e.deptno;

-- 2. 列出薪金比关羽高的所有员工。
SELECT * FROM emp WHERE sal>(SELECT sal FROM emp WHERE ename='关羽');

-- 3. 列出所有员工的姓名及其直接上级的姓名。
SELECT e.ename, m.ename FROM emp e LEFT OUTER JOIN emp m
ON e.mgr=m.empno;

-- 4. 列出受雇日期早于直接上级的所有员工的编号、姓名、部门名称。
SELECT e.empno,e.ename,d.dname FROM emp e ,emp m,dept d 
WHERE e.`mgr`=m.`empno` AND e.`deptno`=d.deptno AND e.hiredate<m.hiredate;

-- 5. 列出部门名称和这些部门的员工信息，同时列出那些没有员工的部门。
SELECT d.dname,e.* FROM dept d LEFT OUTER JOIN emp e
ON d.deptno=e.deptno ;

-- 6. 列出所有文员的姓名及其部门名称，部门的人数。
SELECT e.ename ,d.dname,COUNT(*) FROM emp e,dept d
WHERE e.`deptno`=d.deptno AND e.job='文员'
GROUP BY d.deptno;

-- 7. 列出最低薪金大于15000的各种工作及从事此工作的员工人数。
SELECT job,COUNT(*) FROM emp
GROUP BY job
HAVING MIN(sal)>15000;

-- 8. 列出在销售部工作的员工的姓名，假定不知道销售部的部门编号。
SELECT e.ename,d.dname FROM emp e,dept d
WHERE e.`deptno`=d.deptno AND d.dname='销售部';

-- 9. 列出薪金高于公司平均薪金的所有员工信息，所在部门名称，上级领导，工资等级。
SELECT e.*,m.`ename`,d.dname ,s.grade
FROM emp e LEFT OUTER JOIN emp m ON e.`mgr`=m.`empno` 
	   LEFT OUTER JOIN dept d ON d.deptno=e.`deptno`
	   LEFT OUTER JOIN salgrade s ON e.`sal` BETWEEN s.losal AND s.hisal
WHERE e.sal>(SELECT AVG(sal) FROM emp);

-- 10.列出与庞统从事相同工作的所有员工及部门名称。
SELECT e.*,d.`dname` FROM emp e,dept d
WHERE e.`deptno`=d.deptno AND e.job=(SELECT job FROM emp WHERE ename='庞统');

-- 11.列出薪金高于在部门30工作的所有员工的薪金的员工姓名和薪金、部门名称。
SELECT e.ename,e.sal,d.dname FROM emp e,dept d
WHERE e.`deptno`=d.`deptno` AND e.`sal`>(SELECT MAX(sal) FROM emp WHERE deptno=30);

-- 12.列出每个部门的员工数量、平均工资。
SELECT d.`dname`,COUNT(*),AVG(e.sal) FROM dept d LEFT OUTER JOIN emp e
ON d.`deptno`=e.`deptno`
GROUP BY d.`deptno`;










