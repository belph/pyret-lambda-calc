# ast.arr equivalent for lambda calculus
provide *
import pprint as PP
import srcloc as S
import global as _
import base as _

type Loc = S.Srcloc

dummy-loc = S.builtin("dummy location")

INDENT = 2

str-lambda = PP.str("λ")

data LCVariable:
  | lc-var-inner(loc :: Loc, name :: String) with:
    method to-compiled-source(self): PP.str(self.to-compiled()) end,
    method to-compiled(self): self.name end,
    method tosource(self): PP.str(self.name) end,
    method tosourcestring(self): self.name end,
    method toname(self): self.name end,
    method key(self): "lc-var-inner#" + self.name end
sharing:
  method visit(self, visitor):
    self._match(visitor, lam(): raise("No visitor field for " + self.label()) end)
  end
end

data LCTerm:
  | lc-var(loc :: Loc, name :: LCVariable) with:
    method label(self): "lc-var" end,
    method tosource(self): self.name.tosource() end
  | lc-abs(loc :: Loc, param :: LCVariable, body :: LCTerm) with:
    method label(self): "lc-abs" end,
    method tosource(self):
      pp-arg = PP.surround(INDENT, 0, PP.lparen, self.param.tosource(), PP.rparen)
      PP.surround(INDENT, 0, PP.lparen,
        PP.separate(PP.sbreak(1), [list: str-lambda, pp-arg, self.body.tosource()]), PP.rparen)
    end
  | lc-app(loc :: Loc, func :: LCTerm, arg :: LCTerm) with:
    method label(self): "lc-app" end,
    method tosource(self):
      func = self.func.tosource()
      arg = self.arg.tosource()
      PP.surround(INDENT, 0, PP.lparen,
        PP.separate(PP.sbreak(1), [list: func, arg]), PP.rparen)
    end
sharing:
  method visit(self, visitor):
    self._match(visitor, lam(): raise("No visitor field for " + self.label()) end)
  end
end

fun bound-vars(term) -> List<LCVariable>:
  cases(LCTerm) term:
    | lc-var(_, _) => empty
    | lc-abs(_, param, body) => link(param, bound-vars(body))
    | lc-app(_, func, arg) => bound-vars(func).append(bound-vars(arg))
  end
end

default-map-visitor = {
  method lc-var-inner(self, l, name):
    lc-var-inner(l, name)
  end,

  method lc-var(self, l, inner):
    lc-var(l, inner.visit(self))
  end,

  method lc-abs(self, l, param, body):
    lc-abs(l, param.visit(self), body.visit(self))
  end,

  method lc-app(self, l, fst, snd):
    lc-app(l, fst.visit(self), snd.visit(self))
  end
}

default-iter-visitor = {
  method lc-var-inner(self, l, name):
    true
  end,

  method lc-var(self, l, inner):
    inner.visit(self)
  end,

  method lc-abs(self, l, param, body):
    param.visit(self) and body.visit(self)
  end,

  method lc-app(self, l, fst, snd):
    fst.visit(self) and snd.visit(self)
  end
}

dummy-loc-visitor = {
  method lc-var-inner(self, l, name):
    lc-var-inner(dummy-loc, name)
  end,

  method lc-var(self, l, inner):
    lc-var(dummy-loc, inner.visit(self))
  end,

  method lc-abs(self, l, param, body):
    lc-abs(dummy-loc, param.visit(self), body.visit(self))
  end,

  method lc-app(self, l, fst, snd):
    lc-app(dummy-loc, fst.visit(self), snd.visit(self))
  end
}