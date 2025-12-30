# Fancy prompt, supports showing status of git and hg repositories
# To use, add following to ~/.bashrc
# test -f "${HOME}/.fancy_prompt.sh" && . "${HOME}/.fancy_prompt.sh"

__fancy_prompt_last_result ()
{
  local status=$?

  local -r color_end="\[\e[m\]"
  local -r fg_color_error="\[\e[31m\]"
  local -r fg_color_correct="\[\e[32m\]"

  if [[ ${status} == 0 ]]; then
    printf "%s" "$fg_color_correct✔$color_end"
  else
    printf "%s" "$fg_color_error✘ ($status)$color_end"
  fi
}

__fancy_prompt_name_host ()
{
  printf "%s" "\\u@\\h"
}

__fancy_prompt_time_date ()
{
  printf "%s" "\\A"
}

__fancy_prompt_path ()
{
  printf "%s" "\w"
}

__fancy_prompt_source_control ()
{
  local -r color_end="\[\e[m\]"
  local -r fg_color_repo="\[\e[30m\]"
  local -r fg_color_path="\[\e[96m\]"
  local -r fg_color_name="\[\e[32m\]"
  local -r fg_color_branch="\[\e[35m\]"

  local repo name path branch

  git_client="$(git rev-parse --show-toplevel 2>/dev/null)"
  hg_client="$(hg root 2>/dev/null)"
  jj_client="$(jj root 2>/dev/null)"
  if [[ -n "${git_client}" ]]; then
    repo="git"
    name="$(basename $(git remote get-url origin 2>/dev/null) 2>/dev/null)"
    path="${PWD#${git_client}}"
    branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  elif [[ -n "${hg_client}" ]]; then
    repo="hg"
    name="$(basename $(hg path default 2>/dev/null))"
    path="${PWD#${hg_client}}"
  elif [[ -n "${jj_client}" ]]; then
    repo="jj"
    name="$(basename $(jj git remote list | awk '$1 == "origin" {print $2}' 2>/dev/null))"
    path="${PWD#${jj_client}}"
  fi
  if [[ -n "$repo" ]]; then
    printf "%s" " ${fg_color_repo}${repo}${color_end} ${fg_color_name}[${name}]${color_end}${fg_color_path}/${path}${color_end}"
    if [[ -n "$branch" ]]; then
      printf "%s" " ${fg_color_branch}(${branch})${color_end}]"
    fi

  else
    printf ""
  fi
}

fancy_prompt ()
{
  # -r is readonly
  local -r last_result="$(__fancy_prompt_last_result)"
  local -r name_host="$(__fancy_prompt_name_host)"
  local -r time_date="$(__fancy_prompt_time_date)"
  local -r path="$(__fancy_prompt_path)"
  local -r source_control="$(__fancy_prompt_source_control)"


  local -r color_end="\[\e[m\]"
  local -r fg_color_arrow="\[\e[34m\]"

  PS1="\\n"
  PS1+="${fg_color_arrow}╓${color_end} ${last_result} ${name_host} ${time_date}\\n"
  PS1+="${fg_color_arrow}║${color_end} ${path}${source_control}\\n"
  PS1+="${fg_color_arrow}╙▷${color_end} "
}

PROMPT_COMMAND=fancy_prompt
